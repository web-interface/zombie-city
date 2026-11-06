// [파일] web/kakao_open.js
// [하는 일] 카카오톡 링크로 열었을 때(카톡 안 브라우저) 게임 소리가 안 나므로, 폰의 기본 브라우저(사파리·크롬·삼성 인터넷)로 다시 연다. 카톡 안에서는 게임(약 45MB)을 받지 않고 안내만 보여 주며, '여기서 소리 없이 하기'를 누르면 그 자리에서 시작한다.
// [쓰는 곳] export_presets.cfg 의 head_include 가 불러오고, web/shell.html 이 게임 시작 전에 KakaoInAppBrowser.isInside() 를 묻는다. tools/export_web.py 가 내보낸 폴더로 복사한다.
// [근거 문서] 07 웹 내보내기 (카톡 링크), 09 결정기록 2026-11-07
(function () {
  "use strict";

  var STAY_KEY = "zombie-city-stay-in-kakao";   // '여기서 하기'를 고르면 이 탭에서는 다시 안 묻는다
  // 카톡이 지원하는 '기본 브라우저로 열기' 주소 (공식 문서는 없고 국내 웹에서 널리 쓰는 방식)
  var OPEN_OUTSIDE_PREFIX = "kakaotalk://web/openExternal?url=";

  function isInside() {
    return /KAKAOTALK/i.test(navigator.userAgent) && !stayChosen();
  }

  function stayChosen() {
    try {
      return window.sessionStorage.getItem(STAY_KEY) === "1";
    } catch (error) {
      return false;
    }
  }

  function chooseStay() {
    try {
      window.sessionStorage.setItem(STAY_KEY, "1");
    } catch (error) {
      // 저장이 막힌 브라우저면 이번 한 번만 여기서 한다
    }
  }

  function openOutside() {
    var pageAddress = window.location.href.split("#")[0];
    window.location.href = OPEN_OUTSIDE_PREFIX + encodeURIComponent(pageAddress);
  }

  // 기본 브라우저로 넘기고, 카톡 화면에는 안내와 버튼 두 개를 남긴다
  function leave(startHere) {
    var notice = buildNotice(startHere);
    document.body.appendChild(notice);
    openOutside();
  }

  function buildNotice(startHere) {
    var notice = document.createElement("div");
    notice.id = "kakao-notice";
    notice.style.cssText = "position:fixed;inset:0;display:flex;flex-direction:column;justify-content:center;" +
      "align-items:center;gap:14px;padding:24px;background:#0b0c10;color:#e8e4d8;text-align:center;" +
      "font:16px/1.6 -apple-system,'Apple SD Gothic Neo','Malgun Gothic',sans-serif;z-index:10;";
    notice.appendChild(textLine("카톡 안에서는 게임 소리가 안 나요.", "17px", "#f2c14e"));
    notice.appendChild(textLine("기본 브라우저(사파리·크롬)로 열었어요.\n안 열렸으면 아래 버튼을 눌러 주세요.", "15px", "#e8e4d8"));
    notice.appendChild(button("브라우저로 열기", true, openOutside));
    notice.appendChild(button("여기서 소리 없이 하기", false, function () {
      chooseStay();
      notice.remove();
      startHere();
    }));
    return notice;
  }

  function textLine(text, size, color) {
    var line = document.createElement("p");
    line.style.cssText = "margin:0;white-space:pre-line;font-size:" + size + ";color:" + color + ";";
    line.textContent = text;
    return line;
  }

  function button(label, isMain, onPress) {
    var element = document.createElement("button");
    element.type = "button";
    element.textContent = label;
    element.style.cssText = "min-width:220px;padding:12px 18px;border-radius:6px;font:inherit;font-size:16px;" +
      (isMain ? "background:#f2c14e;color:#14120c;border:0;" : "background:transparent;color:#a9a497;border:1px solid #4a4a52;");
    element.addEventListener("click", onPress);
    return element;
  }

  window.KakaoInAppBrowser = { isInside: isInside, leave: leave };
})();
