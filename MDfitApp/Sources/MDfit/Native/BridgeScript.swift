/// JavaScript injected into every mymdfit.com page in the app (the Android app uses the same script: android/app/src/main/assets/bridge.js
/// is generated from this file by scripts/sync-bridge.sh). It doesn't change the site's behaviour; it
/// listens to what the member app already does (taps, the events account.js dispatches) and asks the native
/// side for the iOS version of it.
enum BridgeScript {
    static let source = #"""
    (function () {
      if (window.MDFitNative) return;
      // iOS: WKScriptMessageHandler "mdfit". Android: the same script, with a JavascriptInterface "mdfitAndroid".
      var post = function (msg) {
        try {
          if (window.mdfitAndroid) window.mdfitAndroid.postMessage(JSON.stringify(msg));
          else window.webkit.messageHandlers.mdfit.postMessage(msg);
        } catch (e) {}
      };
      var isAndroid = !!window.mdfitAndroid;

      // Pages can check window.MDFitNative / html.in-ios-app to tailor themselves to the app
      window.MDFitNative = {
        isApp: true,
        platform: isAndroid ? "android" : "ios",
        haptic: function (style) { post({ action: "haptic", style: style || "light" }); },
        share: function (d) { d = d || {}; post({ action: "share", title: d.title || "", text: d.text || "", url: d.url || "" }); },
        open: function (url) { post({ action: "open", url: String(url || "") }); }
      };
      document.documentElement.classList.add("in-ios-app", isAndroid ? "in-android-app" : "in-ios");

      // navigator.vibrate (gem level-ups, milestones) -> Taptic Engine
      try {
        navigator.vibrate = function (pattern) {
          post({ action: "haptic", style: Array.isArray(pattern) && pattern.length > 1 ? "success" : "medium" });
          return true;
        };
      } catch (e) {}

      // Share (referral code, programs) -> native share sheet
      if (!navigator.share) {
        navigator.share = function (d) { window.MDFitNative.share(d); return Promise.resolve(); };
      }

      // Hide what doesn't apply inside the app:
      //  - "Get the app" / Add to Home Screen cards (they're already in the app)
      //  - Google sign-in: Google blocks sign-in inside apps' web views (email + password works)
      var css =
        "html.in-ios-app .install-card, html.in-ios-app #a2hs," +
        "html.in-ios-app .google-signin-wrap, html.in-ios-app .auth-divider { display: none !important; }" +
        "html.in-ios-app, html.in-ios-app body { -webkit-tap-highlight-color: transparent; }";
      var addStyle = function () {
        var s = document.createElement("style");
        s.textContent = css;
        (document.head || document.documentElement).appendChild(s);
      };
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", addStyle);
      else addStyle();

      // A light tap on buttons, a selection tick on the tab bar
      var lastTap = 0;
      document.addEventListener("click", function (e) {
        var el = e.target && e.target.closest && e.target.closest("button, [role=button], [data-tab], .chip, a.btn, a.btn-gold, a.btn-blue");
        if (!el) return;
        var now = Date.now();
        if (now - lastTap < 60) return;
        lastTap = now;
        post({ action: "haptic", style: el.closest(".tabbar, [data-tab]") ? "selection" : "light" });
      }, true);

      // "Add to calendar" links (.ics) -> native Add Event sheet
      document.addEventListener("click", function (e) {
        var a = e.target && e.target.closest && e.target.closest("a[download]");
        if (!a) return;
        var name = (a.getAttribute("download") || "").toLowerCase();
        var href = a.getAttribute("href") || "";
        if (name.slice(-4) !== ".ics" && href.indexOf("text/calendar") < 0) return;
        e.preventDefault();
        e.stopPropagation();
        fetch(a.href).then(function (r) { return r.text(); })
          .then(function (ics) { post({ action: "calendar", ics: ics }); })
          .catch(function () {});
      }, true);

      // Push notifications: the native side hands over Apple's device token; the page registers it with the
      // member's login (or Dr. Jared's Admin login), so the server knows whose phone it is.
      var deviceToken = "";
      var syncDevice = function () {
        if (!deviceToken) return;
        try {
          var api = (window.MDFIT_CONFIG && window.MDFIT_CONFIG.apiUrl ? window.MDFIT_CONFIG.apiUrl : location.origin).replace(/\/+$/, "");
          var isAdmin = location.pathname.indexOf("/admin") === 0;
          var token = isAdmin ? sessionStorage.getItem("mdfit_token") : (window.MDFit && MDFit.auth && MDFit.auth.get() || {}).token;
          if (!token) return;
          var key = "mdfit-pushed-" + (isAdmin ? "admin" : "member") + "-" + deviceToken.slice(0, 12) + "-" + token.slice(-12);
          if (sessionStorage.getItem(key)) return;
          fetch(api + (isAdmin ? "/api/admin/devices" : "/api/me/devices"), {
            method: "POST", headers: { "Content-Type": "application/json", Authorization: "Bearer " + token },
            body: JSON.stringify({ token: deviceToken, platform: isAndroid ? "android" : "ios" })
          }).then(function (r) { if (r.ok) sessionStorage.setItem(key, "1"); }).catch(function () {});
        } catch (e) {}
      };
      window.MDFitNative.setDeviceToken = function (t) { deviceToken = String(t || ""); syncDevice(); };
      document.addEventListener("mdfit:rewards", syncDevice);          // fires once the member app has loaded signed in
      window.addEventListener("load", function () { setTimeout(syncDevice, 1500); });
      setInterval(syncDevice, 30000);                                   // e.g. Admin signs in without a page reload
      // Signing out: this phone stops getting that person's notifications
      document.addEventListener("click", function (e) {
        var b = e.target && e.target.closest && e.target.closest("#logout");
        if (!b || !deviceToken) return;
        try {
          var api = (window.MDFIT_CONFIG && window.MDFIT_CONFIG.apiUrl ? window.MDFIT_CONFIG.apiUrl : location.origin).replace(/\/+$/, "");
          var isAdmin = location.pathname.indexOf("/admin") === 0;
          var token = isAdmin ? sessionStorage.getItem("mdfit_token") : (window.MDFit && MDFit.auth && MDFit.auth.get() || {}).token;
          if (token) fetch(api + (isAdmin ? "/api/admin/devices/" : "/api/me/devices/") + deviceToken, { method: "DELETE", keepalive: true, headers: { Authorization: "Bearer " + token } }).catch(function () {});
          Object.keys(sessionStorage).forEach(function (k) { if (k.indexOf("mdfit-pushed-") === 0) sessionStorage.removeItem(k); });
        } catch (e) {}
      }, true);

      // Celebrations the site shows (the milestone pop-up and the celebrate toast) -> sound + haptic.
      // The pop-up's kicker says what it is: "New gem!" or "Milestone unlocked".
      var lastSound = 0;
      var sound = function (name) {
        var now = Date.now();
        if (now - lastSound < 400) return;
        lastSound = now;
        post({ action: "sound", name: name });
        post({ action: "haptic", style: "success" });
      };
      var watchCelebrations = function () {
        var ms = document.getElementById("ms"), toast = document.getElementById("toast");
        if (ms) {
          new MutationObserver(function () {
            if (ms.hidden || !ms.classList.contains("play")) return;
            var k = ((document.getElementById("ms-kicker") || {}).textContent || "").toLowerCase();
            sound(k.indexOf("gem") >= 0 ? "gem" : "badge");
          }).observe(ms, { attributes: true, attributeFilter: ["class", "hidden"] });
        }
        if (toast) {
          new MutationObserver(function () {
            if (toast.hidden || !toast.classList.contains("celebrate")) return;
            var t = (toast.textContent || "").toLowerCase();
            if (t.indexOf("new gem") >= 0) sound("gem");
            else if (t.indexOf("badge unlocked") >= 0) sound("badge");
            else if (t.indexOf("daily goal") >= 0) sound("goal");
          }).observe(toast, { attributes: true, attributeFilter: ["class", "hidden"] });
        }
      };
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", watchCelebrations);
      else watchCelebrations();

      // XP earned -> success haptic
      var lastXp = null;
      document.addEventListener("mdfit:rewards", function (e) {
        var r = (e && e.detail) || {};
        if (typeof r.xp === "number") {
          if (lastXp !== null && r.xp > lastXp) { post({ action: "haptic", style: "success" }); setTimeout(function () { if (Date.now() - lastSound > 400) sound("xp"); }, 250); }
          lastXp = r.xp;
        }
      });

      // Finished a workout -> success haptic; first time, ask to allow streak reminders
      document.addEventListener("mdfit:workout", function () {
        post({ action: "haptic", style: "success" });
        post({ action: "askNotifications" });
      });

      // Today's daily-goal status -> schedule (or cancel) tonight's "keep your streak" reminder
      document.addEventListener("mdfit:habits", function (e) {
        var d = (e && e.detail) || {};
        post({
          action: "streak",
          qualifying: !!d.qualifying,
          remaining: d.remaining || 0,
          streak: (d.streak && d.streak.current) || 0
        });
      });
    })();
    """#
}
