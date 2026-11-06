// [파일] web/sound_unlock.js
// [하는 일] 폰 브라우저에서 게임 소리가 나게 한다. ① 아이폰 무음(진동) 모드에서도 소리가 나도록 소리 종류를 '재생'으로 바꾸고(새 iOS 는 navigator.audioSession, 옛 iOS 는 소리 없는 audio 를 반복 재생), ② 손을 뗄 때마다 멈춰 있는 소리 장치(AudioContext)를 다시 켜고, ③ 다른 앱으로 나가면 소리를 멈췄다가 돌아오면 다시 켠다.
// [쓰는 곳] export_presets.cfg 의 head_include 가 <script src="sound_unlock.js"> 로 Godot 보다 먼저 불러온다. tools/export_web.py 가 내보낸 폴더로 복사한다.
// [근거 문서] 07 웹 내보내기 (폰 소리), 09 결정기록 2026-11-07
(function () {
  "use strict";

  var NativeContext = window.AudioContext || window.webkitAudioContext;
  if (!NativeContext) {
    return;
  }
  var contexts = [];          // Godot 가 만든 소리 장치들
  var silentPlayer = null;    // 옛 iOS 용 소리 없는 반복 재생
  var isAppleTouchDevice = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);

  // Godot 가 소리 장치를 만들 때 알아 두려고 생성자를 감싼다 (만드는 방법은 그대로)
  function TrackedContext(options) {
    var context = options === undefined ? new NativeContext() : new NativeContext(options);
    contexts.push(context);
    return context;
  }
  TrackedContext.prototype = NativeContext.prototype;
  window.AudioContext = TrackedContext;
  if (window.webkitAudioContext) {
    window.webkitAudioContext = TrackedContext;
  }

  // 새 iOS(16.4+): 웹 소리 기본 종류는 무음 스위치를 따르는 'ambient' 라서 '재생'으로 바꾼다
  if (navigator.audioSession) {
    try {
      navigator.audioSession.type = "playback";
    } catch (error) {
      // 못 바꾸는 브라우저면 그대로 둔다
    }
  }

  // 옛 iOS: HTML audio 가 재생 중이면 웹 소리 전체가 '재생' 종류가 되는 성질을 쓴다.
  // 안드로이드에서는 하지 않는다 (알림창에 '재생 중' 표시가 뜨므로).
  function startSilentLoop() {
    if (!isAppleTouchDevice || navigator.audioSession || silentPlayer) {
      return;
    }
    silentPlayer = document.createElement("audio");
    silentPlayer.src = silentWavUrl();
    silentPlayer.loop = true;
    silentPlayer.setAttribute("playsinline", "");
    silentPlayer.setAttribute("x-webkit-airplay", "deny");
    var played = silentPlayer.play();
    if (played && played.catch) {
      played.catch(function () { silentPlayer = null; });   // 다음 터치에 다시 시도
    }
  }

  // 0.25초짜리 무음 WAV (8비트 모노 8000Hz) 를 그 자리에서 만든다 — 파일을 따로 두지 않으려고
  function silentWavUrl() {
    var sampleCount = 2000;
    var bytes = new Uint8Array(44 + sampleCount);
    var view = new DataView(bytes.buffer);
    var writeText = function (offset, text) {
      for (var index = 0; index < text.length; index++) {
        bytes[offset + index] = text.charCodeAt(index);
      }
    };
    writeText(0, "RIFF");
    view.setUint32(4, 36 + sampleCount, true);
    writeText(8, "WAVEfmt ");
    view.setUint32(16, 16, true);       // fmt 덩어리 크기
    view.setUint16(20, 1, true);        // PCM
    view.setUint16(22, 1, true);        // 모노
    view.setUint32(24, 8000, true);     // 초당 샘플
    view.setUint32(28, 8000, true);     // 초당 바이트
    view.setUint16(32, 1, true);        // 샘플당 바이트
    view.setUint16(34, 8, true);        // 8비트
    writeText(36, "data");
    view.setUint32(40, sampleCount, true);
    bytes.fill(128, 44);                // 8비트 무음 = 128
    return URL.createObjectURL(new Blob([bytes], { type: "audio/wav" }));
  }

  // 손을 뗄 때(브라우저가 '사용자가 허락함'으로 치는 순간) 소리 장치를 다시 켠다
  function wakeSound() {
    if (document.hidden) {
      return;
    }
    startSilentLoop();
    if (silentPlayer && silentPlayer.paused) {
      silentPlayer.play().catch(function () {});
    }
    contexts.forEach(function (context) {
      if (context.state !== "running" && context.state !== "closed") {
        context.resume().catch(function () {});
      }
    });
  }
  ["touchend", "pointerup", "click", "keydown"].forEach(function (eventName) {
    window.addEventListener(eventName, wakeSound, { capture: true, passive: true });
  });

  // '재생' 종류는 앱을 나가도 소리가 계속 날 수 있어서, 나가면 멈추고 돌아오면 다시 켠다
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) {
      contexts.forEach(function (context) {
        if (context.state === "running") {
          context.suspend().catch(function () {});
        }
      });
      if (silentPlayer) {
        silentPlayer.pause();
      }
    } else {
      wakeSound();
    }
  });
})();
