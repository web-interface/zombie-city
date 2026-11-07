// [파일] web/account.js
// [하는 일] 게임 로그인(웹판은 로그인해야 시작 — 순위표에 기록이 올라감): 저장된 토큰으로 자동 로그인, 로그인·가입·복구 코드로 비밀번호 다시 정하기 창(HTML — 폰 한글 자판 때문에 Godot 글자 입력 대신), 판 결과 올리기, 순위 받아오기. 야구 게임(web/src/api.ts · app/auth.tsx)과 같은 저장 키(bb9.session · bb.user)·같은 PBKDF2(소금 'baseball9:'+아이디 소문자, 21만 번)라서 같은 주소(web-interface.github.io)의 야구에 로그인해 두면 여기서도 바로 로그인돼요. 비밀번호는 보내지 않고 브라우저에서 만든 키만 보낸다.
// [쓰는 곳] export_presets.cfg head_include 가 불러오고, scripts/meta/online.gd 가 JavaScriptBridge 로 window.ZombieCityAccount 를 부른다. 모양은 web/account.css. 서버는 야구 Worker(baseball/worker/src/zc.ts 의 /zc/ 경로).
// [근거 문서] 07 온라인 순위표, 05 순위 화면
(function () {
  "use strict";

  var API = window.ZOMBIE_CITY_API_URL || "https://baseball-api.get943.workers.dev";   // 시험 때만 페이지가 먼저 바꿔 둠
  var TOKEN_KEY = "bb9.session";     // 야구 게임과 같은 키 — 바꾸면 두 게임 로그인이 따로 놀게 됨
  var USER_KEY = "bb.user";
  var REQUEST_TIMEOUT_MS = 12000;
  var USER_RE = /^[A-Za-z0-9가-힣_]{3,16}$/;
  var MIN_PASSWORD = 8;

  var state = { state: "out", username: "", notice: "" };
  var watchers = [];
  var panel = null;

  function read(key) { try { return window.localStorage.getItem(key); } catch (error) { return null; } }
  function write(key, value) { try { window.localStorage.setItem(key, value); } catch (error) { /* 사생활 보호 모드 */ } }
  function remove(key) { try { window.localStorage.removeItem(key); } catch (error) { /* */ } }

  function setState(next, username, notice) {
    state = { state: next, username: username || "", notice: notice || "" };
    var text = JSON.stringify(state);
    watchers.forEach(function (callback) { try { callback(text); } catch (error) { console.warn(error); } });
  }

  function signedIn(username, token) {
    write(TOKEN_KEY, token);
    write(USER_KEY, username);
    setState("in", username);
  }

  function signedOut(notice) {
    remove(TOKEN_KEY);
    remove(USER_KEY);
    setState("out", "", notice);
  }

  function base64Url(buffer) {
    var text = "";
    new Uint8Array(buffer).forEach(function (value) { text += String.fromCharCode(value); });
    return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }

  // 야구 web/src/api.ts passwordKey 와 똑같이 — 하나라도 다르면 같은 비밀번호로 로그인이 안 됨
  function passwordKey(username, password) {
    var encoder = new TextEncoder();
    return crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]).then(function (base) {
      return crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: encoder.encode("baseball9:" + username.toLowerCase()), iterations: 210000 }, base, 256);
    }).then(base64Url);
  }

  // 답: { status, body } — 연결 실패·시간 초과는 status 0 (게임은 그대로 진행)
  function call(method, path, body) {
    var headers = {};
    if (body !== undefined) headers["Content-Type"] = "application/json";
    var token = read(TOKEN_KEY);
    if (token) headers.Authorization = "Bearer " + token;
    var controller = new AbortController();
    var timer = setTimeout(function () { controller.abort(); }, REQUEST_TIMEOUT_MS);
    return fetch(API + path, { method: method, headers: headers, body: body === undefined ? undefined : JSON.stringify(body), signal: controller.signal })
      .then(function (response) {
        return response.json().catch(function () { return {}; }).then(function (data) { return { status: response.status, body: data }; });
      }, function () { return { status: 0, body: { error: "서버에 연결하지 못했어요" } }; })
      .then(function (result) {
        clearTimeout(timer);
        if (result.status === 401 && token && read(TOKEN_KEY) === token) {
          signedOut(result.body.code === "replaced" ? "다른 기기에서 로그인해서 이 기기 접속이 끊겼어요" : "로그인이 만료됐어요");
        }
        return result;
      });
  }

  // 켤 때 자동 로그인 — 야구 app/auth.tsx 와 같은 흐름: 저장된 토큰으로 /me, 인터넷만 끊겼으면 저장된 이름으로
  function checkSaved() {
    if (!read(TOKEN_KEY)) { setState("out"); return; }
    setState("checking", read(USER_KEY));
    call("GET", "/me").then(function (result) {
      if (result.status === 200) { signedIn(result.body.username, read(TOKEN_KEY)); return; }
      if (result.status === 401) return;   // call() 이 이미 로그아웃 처리
      if (read(USER_KEY)) { setState("offline", read(USER_KEY)); return; }
      setState("out");
    });
  }

  function authenticate(mode, username, password, code) {
    return passwordKey(username, password).then(function (key) {
      var body = { username: username, key: key };
      if (mode === "reset") body.recoveryCode = code;
      var path = mode === "login" ? "/auth/login" : mode === "register" ? "/auth/register" : "/auth/reset";
      return call("POST", path, body);
    }).then(function (result) {
      if (result.status !== 200) throw new Error(result.body.error || "문제가 생겼어요. 잠시 뒤 다시 해 주세요");
      signedIn(result.body.username, result.body.token);
      return result.body.recoveryCode || "";
    });
  }

  function logout() {
    return call("POST", "/auth/logout", {}).then(function () { signedOut(""); });
  }

  // ───── 창 (HTML) ─────
  function element(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function field(form, label, type, autocomplete, placeholder) {
    var wrap = element("label", "zc-acc__field");
    wrap.appendChild(element("span", "zc-acc__label", label));
    var input = element("input", "zc-acc__input");
    input.type = type;
    input.autocomplete = autocomplete;
    input.placeholder = placeholder || "";
    input.spellcheck = false;
    input.setAttribute("autocapitalize", "off");
    wrap.appendChild(input);
    form.appendChild(wrap);
    return input;
  }

  function button(parent, className, text, onPress) {
    var node = element("button", className, text);
    node.type = "button";
    node.addEventListener("click", onPress);
    parent.appendChild(node);
    return node;
  }

  // required = 로그인해야 게임을 시작할 수 있을 때 (닫기·바깥 누르기로 못 닫음)
  var required = false;
  function isIn() { return state.state === "in" || state.state === "offline"; }

  function open(isRequired) {
    close();
    required = !!isRequired;
    panel = element("div", "zc-acc");
    panel.setAttribute("role", "dialog");
    panel.setAttribute("aria-modal", "true");
    var sheet = element("div", "zc-acc__sheet");
    panel.appendChild(sheet);
    panel.addEventListener("click", function (event) { if (event.target === panel && (!required || isIn())) close(); });
    document.body.appendChild(panel);
    if (state.state === "in" || state.state === "offline") showAccount(sheet); else showForm(sheet, "login");
  }

  function close() {
    if (!panel) return;
    panel.remove();
    panel = null;
    var canvas = document.getElementById("canvas");
    if (canvas) canvas.focus();   // 창을 닫으면 게임이 다시 키보드를 받게
  }

  function header(sheet, title) {
    sheet.textContent = "";
    var top = element("div", "zc-acc__top");
    top.appendChild(element("p", "zc-acc__kicker", "새벽시 생존자 명부"));
    if (!required || isIn()) button(top, "zc-acc__close", "닫기", close);
    sheet.appendChild(top);
    sheet.appendChild(element("h2", "zc-acc__title", title));
  }

  function showAccount(sheet) {
    header(sheet, state.username);
    sheet.appendChild(element("p", "zc-acc__lead", state.state === "offline" ? "인터넷이 안 돼서 순위에는 아직 못 올려요." : "로그인했어요. 판이 끝나면 기록이 순위표에 올라가요."));
    button(sheet, "zc-acc__main", "확인", close);
    button(sheet, "zc-acc__link", "로그아웃", function () { logout().then(close); });
  }

  var TITLES = { login: "로그인", register: "새로 만들기", reset: "비밀번호 다시 정하기" };
  var ACTIONS = { login: "로그인", register: "만들고 시작하기", reset: "비밀번호 바꾸기" };

  function showForm(sheet, mode) {
    header(sheet, TITLES[mode]);
    sheet.appendChild(element("p", "zc-acc__lead", state.notice || (required ? "게임을 하려면 로그인해요. 판이 끝나면 기록이 순위표에 올라가요." : "로그인하면 판이 끝날 때 기록이 순위표에 올라가요.")));
    if (mode !== "reset") {
      var tabs = element("div", "zc-acc__tabs");
      button(tabs, mode === "login" ? "zc-acc__tab is-on" : "zc-acc__tab", "로그인", function () { showForm(sheet, "login"); });
      button(tabs, mode === "register" ? "zc-acc__tab is-on" : "zc-acc__tab", "새로 만들기", function () { showForm(sheet, "register"); });
      sheet.appendChild(tabs);
    }
    var form = element("form", "zc-acc__form");
    sheet.appendChild(form);
    var username = field(form, "아이디", "text", "username", "한글·영문·숫자 3~16자");
    username.value = read(USER_KEY) || "";
    var code = mode === "reset" ? field(form, "복구 코드", "text", "off", "XXXX-XXXX-XXXX-XXXX") : null;
    var password = field(form, mode === "reset" ? "새 비밀번호" : "비밀번호", "password", mode === "login" ? "current-password" : "new-password", mode === "login" ? "" : "8자 이상");
    var again = mode === "login" ? null : field(form, "비밀번호 확인", "password", "new-password");
    var error = element("p", "zc-acc__error");
    error.setAttribute("role", "alert");
    form.appendChild(error);
    var submit = element("button", "zc-acc__main", ACTIONS[mode]);
    submit.type = "submit";
    form.appendChild(submit);
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var problem = checkInput(mode, username.value.trim(), password.value, again ? again.value : password.value);
      if (problem) { error.textContent = problem; return; }
      submit.disabled = true;
      submit.textContent = "잠시만요";
      authenticate(mode, username.value.trim(), password.value, code ? code.value.trim() : "").then(function (recoveryCode) {
        if (recoveryCode) showRecovery(sheet, recoveryCode); else close();
      }, function (failure) {
        error.textContent = failure.message;
        submit.disabled = false;
        submit.textContent = ACTIONS[mode];
      });
    });
    var link = mode === "reset" ? "로그인으로 돌아가기" : "비밀번호를 잊었어요";
    button(sheet, "zc-acc__link", link, function () { showForm(sheet, mode === "reset" ? "login" : "reset"); });
    if (!username.value) username.focus();
  }

  // 입력은 보낼 때만 검사한다 (아이폰 한글 자판은 조합 중에 글자를 바꿔치기해서, 입력 중에 고치면 글자가 사라짐)
  function checkInput(mode, username, password, again) {
    if (!USER_RE.test(username)) return "아이디는 3~16자 (한글·영문·숫자·_)예요";
    if (!password) return "비밀번호를 넣어 주세요";
    if (mode !== "login" && password.length < MIN_PASSWORD) return "비밀번호는 8자 이상으로 해 주세요";
    if (password !== again) return "비밀번호 확인이 달라요";
    return "";
  }

  function showRecovery(sheet, code) {
    header(sheet, "복구 코드를 적어 두세요");
    sheet.appendChild(element("p", "zc-acc__lead", "비밀번호를 잊었을 때 필요해요. 지금 한 번만 보여요."));
    sheet.appendChild(element("p", "zc-acc__code", code));
    var copy = button(sheet, "zc-acc__link", "복사하기", function () {
      if (navigator.clipboard) navigator.clipboard.writeText(code).then(function () { copy.textContent = "복사했어요"; }, function () {});
    });
    button(sheet, "zc-acc__main", "적어 뒀어요", close);
  }

  // ───── 게임(online.gd)이 부르는 것 — 답은 모두 JSON 글로 ─────
  function answer(callback, result) {
    var body = result.body || {};
    body.ok = result.status === 200;
    body.status = result.status;
    try { callback(JSON.stringify(body)); } catch (error) { console.warn(error); }
  }

  window.ZombieCityAccount = {
    state: function () { return JSON.stringify(state); },
    watch: function (callback) { watchers.push(callback); },
    open: open,
    logout: logout,
    // 판 결과 올리기 — 1분 막기(429)에 걸리면 기다렸다가 한 번 더
    submitRun: function (runJson, callback) {
      var run = JSON.parse(runJson);
      call("POST", "/zc/runs", run).then(function (result) {
        if (result.status !== 429 || !(result.body.retryAfter > 0)) { answer(callback, result); return; }
        setTimeout(function () { call("POST", "/zc/runs", run).then(function (retry) { answer(callback, retry); }); }, (result.body.retryAfter + 1) * 1000);
      });
    },
    rank: function (board, callback) {
      call("GET", "/zc/rank?board=" + encodeURIComponent(board) + "&limit=50").then(function (result) { answer(callback, result); });
    },
  };

  checkSaved();
})();
