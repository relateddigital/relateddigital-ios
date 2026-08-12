/*
 * Plinko Game - Related Digital / Visilabs
 *
 * Bu dosya sunucuya (mbls.visilabs.net/plinko.js) yüklenir ve SDK tarafından
 * çalışma zamanında indirilerek plinko.html içine enjekte edilir.
 *
 * Oyun tamamen panelden (backend JSON'u) özelleştirilebilir. Tüm görsel
 * ayarlar `actiondata.ExtendedProps` (url-encoded JSON) içinden okunur.
 * Çarkıfelekteki dilimler burada topun düştüğü "slot"lara karşılık gelir
 * (actiondata.slices).
 */

function Plinko(config) {
    this.config = config || {};
    this.actionData = this.config.actiondata || {};

    // ExtendedProps url-encoded bir JSON string olarak gelir.
    this.props = Plinko.parseExtendedProps(this.actionData.ExtendedProps);

    this.slices = this.actionData.slices || [];
    this.content = this.actionData.plinko_content || {};

    // Peg satır sayısı (görsel). Panelden özelleştirilebilir.
    this.rowCount = parseInt(this.actionData.row_count, 10) || 12;
    if (this.rowCount < 4) this.rowCount = 4;
    if (this.rowCount > 16) this.rowCount = 16;

    // Top kaç kez oynanabilir. "button" => kullanıcı butona basar, "auto" => otomatik düşer.
    this.dropAction = this.actionData.ball_drop_action || "button";

    this.mailSubscription = !!this.actionData.mail_subscription;
    this.emailSubscribed = false;
    this.dropping = false;
    this.finished = false;

    this.selectedIndex = -1;
    this.selectedCode = "";

    // Ses ayarları (panelden özelleştirilebilir)
    this.soundEnabled = this.p("sound_enabled", "true") !== "false";
    this.dropSoundUrl = this.p("drop_sound_url", "");
    this.winSoundUrl = this.p("win_sound_url", "");
    this.audioCtx = null;
    this._lastTick = 0;

    this.injectStyles();
    this.render();
}

/* ------------------------------------------------------------------ */
/* Native köprüsü                                                      */
/* ------------------------------------------------------------------ */

Plinko.post = function (payload) {
    try {
        if (!Plinko.hasNativeBridge()) {
            // Tarayıcıda lokal test: native olmadan mesajları makul şekilde ele al.
            Plinko.browserFallback(payload);
            return;
        }
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.eventHandler) {
            window.webkit.messageHandlers.eventHandler.postMessage(payload);
        } else if (window.Android) {
            var method = payload.method;
            if (method === "subscribeEmail" && window.Android.subscribeEmail) {
                window.Android.subscribeEmail(payload.email);
            } else if (method === "getPromotionCode" && window.Android.getPromotionCode) {
                window.Android.getPromotionCode();
            } else if (method === "sendReport" && window.Android.sendReport) {
                window.Android.sendReport();
            } else if (method === "copyToClipboard" && window.Android.copyToClipboard) {
                window.Android.copyToClipboard(payload.couponCode, payload.sliceLink || "");
            } else if (method === "openUrl" && window.Android.openUrl) {
                window.Android.openUrl(payload.url);
            } else if (method === "close" && window.Android.close) {
                window.Android.close();
            } else if (method === "console.log" && window.Android.log) {
                window.Android.log(payload.message);
            }
        }
    } catch (e) {
        /* sessizce yut */
    }
};

Plinko.log = function (message) {
    Plinko.post({ method: "console.log", message: typeof message === "string" ? message : JSON.stringify(message) });
};

// Native köprü (iOS webkit / Android) var mı? Yoksa tarayıcıda test ediliyoruz.
Plinko.hasNativeBridge = function () {
    return !!(window.Android ||
        (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.eventHandler));
};

// Sadece lokal tarayıcı testi içindir.
Plinko.browserFallback = function (payload) {
    var method = payload.method;
    if (method === "copyToClipboard") {
        if (navigator.clipboard && payload.couponCode) {
            navigator.clipboard.writeText(payload.couponCode).catch(function () {});
        }
        Plinko.toast("Kod kopyalandı: " + (payload.couponCode || ""));
    } else if (method === "openUrl" && payload.url) {
        window.open(payload.url, "_blank");
    } else if (method === "close") {
        Plinko.toast("close");
    } else {
        try { console.log("[Plinko]", method, payload); } catch (e) {}
    }
};

Plinko.toast = function (message) {
    var el = document.createElement("div");
    el.textContent = message;
    el.style.cssText = "position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:rgba(0,0,0,0.8);color:#fff;padding:10px 18px;border-radius:20px;font-size:14px;z-index:9999;";
    document.body.appendChild(el);
    setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 1800);
};

Plinko.parseExtendedProps = function (raw) {
    if (!raw) return {};
    try {
        return JSON.parse(decodeURIComponent(raw));
    } catch (e) {
        try {
            return JSON.parse(decodeURI(raw));
        } catch (e2) {
            try {
                return JSON.parse(raw);
            } catch (e3) {
                return {};
            }
        }
    }
};

// Bir hex rengi verilen yüzde kadar açar (+) / koyulaştırır (-).
// Hex olmayan (rgba vb.) renklerde rengi olduğu gibi döndürür.
Plinko.shade = function (color, percent) {
    if (typeof color !== "string") return color;
    var hex = color.trim();
    var m = /^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.exec(hex);
    if (!m) return color;
    hex = m[1];
    if (hex.length === 3) {
        hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    }
    var r = parseInt(hex.substr(0, 2), 16);
    var g = parseInt(hex.substr(2, 2), 16);
    var b = parseInt(hex.substr(4, 2), 16);
    var t = percent < 0 ? 0 : 255;
    var f = Math.abs(percent) / 100;
    r = Math.round((t - r) * f) + r;
    g = Math.round((t - g) * f) + g;
    b = Math.round((t - b) * f) + b;
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
};

/* ------------------------------------------------------------------ */
/* Yardımcılar                                                         */
/* ------------------------------------------------------------------ */

Plinko.prototype.p = function (key, fallback) {
    var v = this.props[key];
    if (v === undefined || v === null || v === "") return fallback;
    return v;
};

// Panelden gelen "1".."6" gibi text_size değerlerini vmin cinsine çevirir.
Plinko.prototype.fontSize = function (key, base) {
    var raw = this.p(key, null);
    var n = parseFloat(raw);
    if (isNaN(n) || n <= 0) n = base || 2;
    return (2.4 + n * 0.9).toFixed(2) + "vmin";
};

Plinko.prototype.fontFamily = function (familyKey, customIosKey) {
    var family = this.p(familyKey, "default");
    if (family === "custom") {
        var custom = this.p(customIosKey, "");
        if (custom) return "'" + custom + "', sans-serif";
    }
    return "inherit";
};

Plinko.prototype.clean = function (text) {
    if (!text) return "";
    return String(text).replace(/\\n/g, "\n");
};

/* ------------------------------------------------------------------ */
/* Stiller (tamamı JS ile yazılır)                                     */
/* ------------------------------------------------------------------ */

Plinko.prototype.injectStyles = function () {
    var bgColor = this.p("background_color", "#1b1436");
    var bgImage = this.p("background_image", "");
    var boardColor = this.p("board_background_color", "rgba(0,0,0,0.25)");
    var boardRadius = this.p("board_border_radius", "18");
    var formCardColor = this.p("form_background_color", "rgba(0,0,0,0.30)");
    var inputBgColor = this.p("input_background_color", "rgba(255,255,255,0.14)");
    var pegColor = this.p("peg_color", "#ffffff");
    var pegSize = parseFloat(this.p("peg_size", "1.7")) || 1.7;
    var ballColor = this.p("ball_color", "#ffd23f");
    var ballSize = parseFloat(this.p("ball_size", "3.4")) || 3.4;
    var ballBorderColor = this.p("ball_border_color", "#ffffff");

    var closeColor = this.p("close_button_color", "#ffffff");

    var titleColor = this.p("title_text_color", "#ffffff");
    var textColor = this.p("text_color", "#e9e4ff");

    var buttonColor = this.p("button_color", "#ff477e");
    var buttonTextColor = this.p("button_text_color", "#ffffff");
    var buttonRadius = this.p("button_border_radius", "28");

    var slotTextColor = this.p("slot_text_color", "#ffffff");
    var slotBorderColor = this.p("slot_border_color", "rgba(255,255,255,0.25)");
    var slotBorderWidth = parseFloat(this.p("slot_border_width", "1")) || 1;
    var slotRadius = this.p("slot_border_radius", "8");

    var promoBg = this.p("promocode_background_color", "#ffffff");
    var promoColor = this.p("promocode_text_color", "#1b1436");
    var copyColor = this.p("copybutton_color", "#ff477e");
    var copyTextColor = this.p("copybutton_text_color", "#ffffff");

    var backgroundRule = bgImage
        ? "background: url('" + bgImage + "') center/cover no-repeat, " + bgColor + ";"
        : "background: " + bgColor + ";";

    var css = [
        "*{box-sizing:border-box;-webkit-tap-highlight-color:transparent;}",
        "html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;}",
        "#rd-plinko{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:flex-start;" + backgroundRule + "color:" + textColor + ";padding:calc(env(safe-area-inset-top) + 52px) 0 env(safe-area-inset-bottom);}",
        "#rd-plinko .rd-topbar{position:absolute;top:calc(env(safe-area-inset-top) + 8px);right:12px;display:flex;align-items:center;gap:8px;z-index:50;}",
        "#rd-plinko .rd-icon-btn{width:38px;height:38px;border-radius:50%;border:1.5px solid " + closeColor + ";background:rgba(255,255,255,0.08);color:" + closeColor + ";font-size:20px;font-weight:600;line-height:1;display:flex;align-items:center;justify-content:center;cursor:pointer;padding:0;transition:transform 0.1s ease,background 0.2s ease;}",
        "#rd-plinko .rd-icon-btn:active{transform:scale(0.9);}",
        "#rd-plinko .rd-close-btn{font-size:26px;font-weight:300;}",
        "#rd-plinko .rd-help{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;background:rgba(0,0,0,0.82);z-index:70;padding:28px;text-align:center;opacity:0;pointer-events:none;transition:opacity 0.25s ease;}",
        "#rd-plinko .rd-help.rd-show{opacity:1;pointer-events:auto;}",
        "#rd-plinko .rd-help-title{color:" + titleColor + ";font-size:" + this.fontSize("title_text_size", 4) + ";font-weight:700;margin-bottom:16px;}",
        "#rd-plinko .rd-help-text{color:" + textColor + ";font-size:" + this.fontSize("text_size", 2) + ";line-height:1.5;white-space:pre-line;max-width:520px;}",
        "#rd-plinko .rd-help-close{margin-top:22px;}",
        "#rd-plinko .rd-title{margin:14px 18px 4px;text-align:center;color:" + titleColor + ";font-size:" + this.fontSize("title_text_size", 4) + ";font-family:" + this.fontFamily("title_font_family", "title_custom_font_family_ios") + ";white-space:pre-line;font-weight:700;}",
        "#rd-plinko .rd-text{margin:0 22px 8px;text-align:center;color:" + textColor + ";font-size:" + this.fontSize("text_size", 2) + ";font-family:" + this.fontFamily("text_font_family", "text_custom_font_family_ios") + ";white-space:pre-line;opacity:0.9;line-height:1.35;}",
        "#rd-plinko .rd-board{position:relative;width:min(92vw,520px);flex:1 1 auto;margin:8px 0;background:" + boardColor + ";border-radius:" + boardRadius + "px;overflow:hidden;box-shadow:inset 0 0 0 1px rgba(255,255,255,0.06), inset 0 10px 40px rgba(0,0,0,0.25);}",
        "#rd-plinko .rd-board::before{content:'';position:absolute;inset:0;z-index:0;pointer-events:none;background:radial-gradient(120% 60% at 50% -5%, " + ballColor + "22, transparent 55%), radial-gradient(90% 50% at 50% 105%, " + buttonColor + "22, transparent 60%);animation:rd-board-glow 6s ease-in-out infinite;}",
        "@keyframes rd-board-glow{0%,100%{opacity:0.65;}50%{opacity:1;}}",
        "#rd-plinko .rd-peg{position:absolute;width:" + pegSize + "vmin;height:" + pegSize + "vmin;max-width:14px;max-height:14px;min-width:6px;min-height:6px;background:radial-gradient(circle at 35% 30%, #ffffff, " + pegColor + " 72%);border-radius:50%;transform:translate(-50%,-50%);box-shadow:0 1px 3px rgba(0,0,0,0.4), 0 0 6px " + pegColor + "55;z-index:2;}",
        "#rd-plinko .rd-peg.rd-hit{animation:rd-peg-hit 0.3s ease;}",
        "@keyframes rd-peg-hit{0%{transform:translate(-50%,-50%) scale(1);}35%{transform:translate(-50%,-50%) scale(1.8);box-shadow:0 0 14px 4px " + pegColor + ";}100%{transform:translate(-50%,-50%) scale(1);}}",
        "#rd-plinko .rd-ball{position:absolute;width:" + ballSize + "vmin;height:" + ballSize + "vmin;max-width:28px;max-height:28px;min-width:12px;min-height:12px;background:radial-gradient(circle at 32% 28%, #ffffff, " + ballColor + " 62%);border:1px solid " + ballBorderColor + ";border-radius:50%;transform:translate(-50%,-50%);z-index:20;box-shadow:0 2px 8px rgba(0,0,0,0.45), 0 0 14px " + ballColor + "cc;will-change:left,top,transform;}",
        "#rd-plinko .rd-ball.rd-ball-idle{animation:rd-ball-bob 1.6s ease-in-out infinite;}",
        "@keyframes rd-ball-bob{0%,100%{transform:translate(-50%,-50%);}50%{transform:translate(-50%,-58%);}}",
        "#rd-plinko .rd-trail{position:absolute;border-radius:50%;background:radial-gradient(circle, " + ballColor + "cc, " + ballColor + "00 70%);transform:translate(-50%,-50%);z-index:19;pointer-events:none;animation:rd-trail-fade 0.5s ease forwards;}",
        "@keyframes rd-trail-fade{0%{opacity:0.7;}100%{opacity:0;transform:translate(-50%,-50%) scale(0.4);}}",
        "#rd-plinko .rd-slots{position:absolute;left:0;right:0;bottom:0;height:12%;min-height:42px;}",
        "#rd-plinko .rd-slot{position:absolute;bottom:0;display:flex;align-items:center;justify-content:center;text-align:center;height:100%;padding:2px;color:" + slotTextColor + ";font-size:" + this.fontSize("displayname_text_size", 2) + ";font-family:" + this.fontFamily("displayname_font_family", "displayname_custom_font_family_ios") + ";border:" + slotBorderWidth + "px solid " + slotBorderColor + ";border-radius:" + slotRadius + "px " + slotRadius + "px 4px 4px;overflow:hidden;line-height:1.02;transition:transform 0.15s ease, box-shadow 0.15s ease;box-sizing:border-box;}",
        "#rd-plinko .rd-slot::before{content:'';position:absolute;inset:0;border-radius:inherit;pointer-events:none;background:linear-gradient(180deg, rgba(255,255,255,0.35), rgba(255,255,255,0) 45%, rgba(0,0,0,0.14));}",
        "#rd-plinko .rd-slot > span{position:relative;z-index:1;}",
        "#rd-plinko .rd-slot.rd-win{animation:rd-slot-win 0.6s ease infinite alternate;z-index:5;}",
        "@keyframes rd-slot-win{0%{transform:translateY(-6px) scale(1.05);box-shadow:0 -4px 16px rgba(255,255,255,0.55);}100%{transform:translateY(-11px) scale(1.1);box-shadow:0 -8px 26px rgba(255,255,255,0.9);}}",
        "#rd-plinko .rd-slot-vertical{writing-mode:vertical-rl;transform:rotate(180deg);}",
        "#rd-plinko .rd-slot-vertical.rd-win{animation:none;transform:rotate(180deg) translateY(8px) scale(1.08);box-shadow:0 8px 24px rgba(255,255,255,0.8);}",
        "#rd-plinko .rd-confetti{position:absolute;top:-12px;width:9px;height:14px;z-index:65;pointer-events:none;will-change:transform,opacity;}",
        "@keyframes rd-confetti-fall{0%{opacity:1;transform:translateY(-10px) rotateZ(0deg);}100%{opacity:0;transform:translateY(var(--rd-cy)) translateX(var(--rd-cx)) rotateZ(var(--rd-cr));}}",
        "#rd-plinko .rd-actions{width:100%;display:flex;flex-direction:column;align-items:center;padding:6px 0 16px;}",
        "#rd-plinko .rd-btn{border:none;cursor:pointer;padding:14px 34px;margin:6px;border-radius:" + buttonRadius + "px;background:" + buttonColor + ";color:" + buttonTextColor + ";font-size:" + this.fontSize("button_text_size", 3) + ";font-family:" + this.fontFamily("button_font_family", "button_custom_font_family_ios") + ";font-weight:600;box-shadow:0 6px 18px rgba(0,0,0,0.3);transition:transform 0.1s ease,opacity 0.2s ease;}",
        "#rd-plinko .rd-btn:active{transform:scale(0.96);}",
        "#rd-plinko .rd-btn[disabled]{opacity:0.5;pointer-events:none;}",
        "#rd-plinko .rd-drop-btn{position:relative;overflow:hidden;background:linear-gradient(135deg, " + buttonColor + ", " + Plinko.shade(buttonColor, -18) + ");animation:rd-drop-pulse 1.8s ease-in-out infinite;}",
        "#rd-plinko .rd-drop-btn::after{content:'';position:absolute;top:0;left:-60%;width:45%;height:100%;background:linear-gradient(100deg, transparent, rgba(255,255,255,0.45), transparent);transform:skewX(-20deg);animation:rd-drop-shine 2.6s ease-in-out infinite;}",
        "#rd-plinko .rd-drop-btn[disabled]{animation:none;}",
        "#rd-plinko .rd-drop-btn[disabled]::after{display:none;}",
        "@keyframes rd-drop-pulse{0%,100%{transform:scale(1);box-shadow:0 6px 18px rgba(0,0,0,0.3);}50%{transform:scale(1.045);box-shadow:0 10px 26px " + buttonColor + "88;}}",
        "@keyframes rd-drop-shine{0%{left:-60%;}45%,100%{left:130%;}}",
        "#rd-plinko .rd-form{width:min(88vw,430px);display:flex;flex-direction:column;align-items:center;margin:auto;padding:8px 0;}",
        "#rd-plinko .rd-card{width:100%;display:flex;flex-direction:column;align-items:stretch;gap:14px;padding:26px 22px 24px;border-radius:24px;background:" + formCardColor + ";border:1px solid rgba(255,255,255,0.16);box-shadow:0 20px 50px rgba(0,0,0,0.35);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);animation:rd-card-in 0.45s cubic-bezier(0.2,0.9,0.3,1) both;}",
        "@keyframes rd-card-in{0%{opacity:0;transform:translateY(24px) scale(0.96);}100%{opacity:1;transform:translateY(0) scale(1);}}",
        "#rd-plinko .rd-form-icon{width:60px;height:60px;margin:0 auto 2px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:" + buttonColor + ";color:" + buttonTextColor + ";box-shadow:0 8px 20px rgba(0,0,0,0.28);}",
        "#rd-plinko .rd-form-title{margin:0;text-align:center;color:" + titleColor + ";font-size:" + this.fontSize("title_text_size", 4) + ";font-family:" + this.fontFamily("title_font_family", "title_custom_font_family_ios") + ";white-space:pre-line;font-weight:700;line-height:1.2;}",
        "#rd-plinko .rd-form-msg{margin:-4px 0 2px;text-align:center;color:" + textColor + ";font-size:" + this.fontSize("text_size", 2) + ";font-family:" + this.fontFamily("text_font_family", "text_custom_font_family_ios") + ";white-space:pre-line;opacity:0.88;line-height:1.4;}",
        "#rd-plinko .rd-input{width:100%;padding:15px 16px;border-radius:14px;border:1.5px solid rgba(255,255,255,0.28);background:" + inputBgColor + ";color:#fff;font-size:2.1vmin;outline:none;transition:border-color 0.2s ease,background 0.2s ease;}",
        "#rd-plinko .rd-input::placeholder{color:rgba(255,255,255,0.65);}",
        "#rd-plinko .rd-input:focus{border-color:" + buttonColor + ";background:rgba(255,255,255,0.2);}",
        "#rd-plinko .rd-consent{display:flex;align-items:center;gap:10px;font-size:1.85vmin;margin:0;text-align:left;color:" + textColor + ";line-height:1.35;cursor:pointer;}",
        "#rd-plinko .rd-consent input[type=checkbox]{width:20px;height:20px;flex:0 0 auto;margin:0;accent-color:" + buttonColor + ";cursor:pointer;}",
        "#rd-plinko .rd-consent a{color:" + titleColor + ";text-decoration:underline;}",
        "#rd-plinko .rd-permit{font-size:1.7vmin;margin:0;text-align:left;color:" + textColor + ";opacity:0.72;line-height:1.35;}",
        "#rd-plinko .rd-permit a{color:" + titleColor + ";text-decoration:underline;}",
        "#rd-plinko .rd-error{color:#ff8a8a;font-size:1.85vmin;min-height:1.1em;text-align:center;margin:-4px 0 0;}",
        "#rd-plinko .rd-form-btn{width:100%;margin:6px 0 0;}",
        "#rd-plinko .rd-overlay{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;background:rgba(0,0,0,0.55);z-index:60;padding:24px;text-align:center;opacity:0;pointer-events:none;transition:opacity 0.3s ease;}",
        "#rd-plinko .rd-overlay.rd-show{opacity:1;pointer-events:auto;}",
        "#rd-plinko .rd-result-title{color:" + titleColor + ";font-size:" + this.fontSize("promocode_title_text_size", 3) + ";font-family:" + this.fontFamily("promocode_title_font_family", "promocode_title_custom_font_family_ios") + ";white-space:pre-line;font-weight:700;margin-bottom:14px;}",
        "#rd-plinko .rd-code{background:" + promoBg + ";color:" + promoColor + ";font-size:3.2vmin;font-weight:700;letter-spacing:1px;padding:12px 22px;border-radius:10px;margin:8px 0;}",
        "#rd-plinko .rd-copy{background:" + copyColor + ";color:" + copyTextColor + ";font-size:" + this.fontSize("copybutton_text_size", 2) + ";font-family:" + this.fontFamily("copybutton_font_family", "copybutton_custom_font_family_ios") + ";}",
        "#rd-plinko .rd-soldout{color:" + this.p("promocodes_soldout_message_text_color", "#ffffff") + ";background:" + this.p("promocodes_soldout_message_background_color", "transparent") + ";font-size:" + this.fontSize("promocodes_soldout_message_text_size", 3) + ";padding:16px;border-radius:12px;white-space:pre-line;}"
    ].join("\n");

    var style = document.createElement("style");
    style.type = "text/css";
    style.appendChild(document.createTextNode(css));
    document.head.appendChild(style);
};

/* ------------------------------------------------------------------ */
/* Render                                                              */
/* ------------------------------------------------------------------ */

Plinko.prototype.render = function () {
    var self = this;
    document.body.innerHTML = "";

    var root = document.createElement("div");
    root.id = "rd-plinko";
    this.root = root;

    // Sağ üst buton çubuğu: [?] [ses] [×]
    var topBar = document.createElement("div");
    topBar.className = "rd-topbar";

    var help = document.createElement("button");
    help.className = "rd-icon-btn";
    help.innerHTML = "?";
    help.setAttribute("aria-label", "info");
    help.onclick = function () { self.toggleHelp(); };
    topBar.appendChild(help);

    var sound = document.createElement("button");
    sound.className = "rd-icon-btn";
    sound.setAttribute("aria-label", "sound");
    this.soundBtn = sound;
    sound.onclick = function () { self.toggleSound(); };
    topBar.appendChild(sound);

    var close = document.createElement("button");
    close.className = "rd-icon-btn rd-close-btn";
    close.innerHTML = "&times;";
    close.onclick = function () { Plinko.post({ method: "close" }); };
    topBar.appendChild(close);

    root.appendChild(topBar);
    this.updateSoundIcon();

    document.body.appendChild(root);

    this.buildHelpOverlay();

    // Impression report
    Plinko.post({ method: "sendReport" });

    if (this.mailSubscription && !this.emailSubscribed) {
        this.renderEmailForm();
    } else {
        this.renderGame();
    }
};

Plinko.prototype.renderEmailForm = function () {
    var self = this;
    this.clearContent();

    // Ortalanmış frosted-glass kart
    var wrap = document.createElement("div");
    wrap.className = "rd-form";

    var card = document.createElement("div");
    card.className = "rd-card";
    wrap.appendChild(card);

    // Zarf ikonu (panelden gizlenebilir: show_form_icon = "false")
    if (this.p("show_form_icon", "true") !== "false") {
        var icon = document.createElement("div");
        icon.className = "rd-form-icon";
        icon.innerHTML = "<svg width='28' height='28' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='5' width='18' height='14' rx='2.5'/><path d='M3.5 7l8.5 6 8.5-6'/></svg>";
        card.appendChild(icon);
    }

    if (this.content.title) {
        var title = document.createElement("div");
        title.className = "rd-form-title";
        title.textContent = this.clean(this.content.title);
        card.appendChild(title);
    }

    if (this.content.message) {
        var msg = document.createElement("div");
        msg.className = "rd-form-msg";
        msg.textContent = this.clean(this.content.message);
        card.appendChild(msg);
    }

    var input = document.createElement("input");
    input.className = "rd-input";
    input.type = "email";
    input.autocapitalize = "off";
    input.autocomplete = "email";
    input.placeholder = this.content.placeholder || "";
    card.appendChild(input);

    var consentCheck = null;
    if (this.content.consent_text) {
        var consentWrap = document.createElement("label");
        consentWrap.className = "rd-consent";
        consentCheck = document.createElement("input");
        consentCheck.type = "checkbox";
        var consentText = document.createElement("span");
        consentText.innerHTML = this.linkify(this.content.consent_text, this.p("consent_text_url", ""));
        consentWrap.appendChild(consentCheck);
        consentWrap.appendChild(consentText);
        card.appendChild(consentWrap);
    }

    if (this.content.emailpermit_text) {
        var permit = document.createElement("div");
        permit.className = "rd-permit";
        permit.innerHTML = this.linkify(this.content.emailpermit_text, this.p("emailpermit_text_url", ""));
        card.appendChild(permit);
    }

    var error = document.createElement("div");
    error.className = "rd-error";
    card.appendChild(error);

    var btn = document.createElement("button");
    btn.className = "rd-btn rd-form-btn";
    btn.textContent = this.content.button_label || "OK";
    btn.onclick = function () {
        var email = (input.value || "").trim();
        if (!self.isValidEmail(email)) {
            error.textContent = self.content.invalid_email_message || "Invalid email";
            return;
        }
        if (consentCheck && !consentCheck.checked) {
            error.textContent = self.content.check_consent_message || "";
            return;
        }
        error.textContent = "";
        Plinko.post({ method: "subscribeEmail", email: email });
        self.emailSubscribed = true;
        self.renderGame();
    };
    card.appendChild(btn);

    this.root.appendChild(wrap);
};

Plinko.prototype.renderGame = function () {
    var self = this;
    this.clearContent();

    var props = this.props;

    var titlePos = this.p("title_position", "top");
    var textPos = this.p("text_position", "top");
    var buttonPos = this.p("button_position", "bottom");

    var titleEl = document.createElement("div");
    titleEl.className = "rd-title";
    titleEl.textContent = this.clean(this.content.title);

    var textEl = document.createElement("div");
    textEl.className = "rd-text";
    textEl.textContent = this.clean(this.content.message);

    if (titlePos === "top" && this.content.title) this.root.appendChild(titleEl);
    if (textPos === "top" && this.content.message) this.root.appendChild(textEl);

    // Board
    var board = document.createElement("div");
    board.className = "rd-board";
    this.board = board;
    this.root.appendChild(board);

    // Slots (topun düşeceği boşlukların altına hizalanır)
    var slots = document.createElement("div");
    slots.className = "rd-slots";
    this.slotsEl = slots;
    this.slotEls = [];
    var vertical = this.p("displayname_text_align", "horizontal") === "vertical";
    this.slices.forEach(function (slice, i) {
        var slot = document.createElement("div");
        slot.className = "rd-slot" + (vertical ? " rd-slot-vertical" : "");
        slot.style.background = slice.color || "rgba(255,255,255,0.08)";
        var label = document.createElement("span");
        label.textContent = self.clean(slice.displayName);
        slot.appendChild(label);
        slots.appendChild(slot);
        self.slotEls.push(slot);
    });
    board.appendChild(slots);

    // Overlay (result / soldout)
    var overlay = document.createElement("div");
    overlay.className = "rd-overlay";
    this.overlay = overlay;
    board.appendChild(overlay);

    // Actions
    var actions = document.createElement("div");
    actions.className = "rd-actions";

    if (titlePos !== "top" && this.content.title) actions.appendChild(titleEl);
    if (textPos !== "top" && this.content.message) actions.appendChild(textEl);

    var dropBtn = document.createElement("button");
    dropBtn.className = "rd-btn rd-drop-btn";
    dropBtn.textContent = this.content.button_label || "DROP";
    this.dropBtn = dropBtn;
    dropBtn.onclick = function () { self.requestDrop(); };
    actions.appendChild(dropBtn);

    this.root.appendChild(actions);

    // Pegleri board boyutu hazır olunca çiz
    requestAnimationFrame(function () {
        self.layoutPegs();
        self.placeBall();
        if (self.dropAction === "auto") {
            setTimeout(function () { self.requestDrop(); }, 600);
        }
    });

    window.addEventListener("resize", function () {
        self.layoutPegs();
        if (!self.dropping) self.placeBall();
    });
};

// Klasik Plinko dizilişi: kaydırmalı (staggered) üçgen.
// N slot için R = N - 1 peg satırı; en alt satırda N + 1 peg olur ve
// aralarındaki N boşluk (gap) tam olarak N slotun üstüne denk gelir.
Plinko.prototype.layoutPegs = function () {
    if (!this.board) return;

    var old = this.board.querySelectorAll(".rd-peg");
    for (var k = 0; k < old.length; k++) old[k].parentNode.removeChild(old[k]);
    this.pegEls = [];

    var w = this.board.clientWidth;
    var h = this.board.clientHeight;
    var slotsHeight = this.slotsEl ? this.slotsEl.clientHeight : h * 0.12;

    var N = this.slices.length;
    var rows = Math.max(N - 1, 1);
    this.pegRows = rows;

    var usableTop = h * 0.05;
    var usableBottom = h - slotsHeight - h * 0.01;

    // Yatay peg aralığı: en alt satır N+1 peg, kenarlarda birer aralık boşluk.
    var s = w / (N + 1.4);
    var center = w / 2;

    // Dikey aralık: mevcut alanı mümkün olduğunca doldur; sadece çok az satır
    // olduğunda aşırı gerilmesin diye yatay aralığın ~1.6 katıyla sınırla.
    var maxGap = rows > 1 ? (usableBottom - usableTop) / (rows - 1) : 0;
    var rowGap = Math.min(maxGap, s * 1.6);
    var pegHeight = rowGap * (rows - 1);
    // Artan boşluğun çoğunu üste bırak (top yukarıdan düşsün), altta slotlara yakın dursun.
    var pegTop = usableTop + (usableBottom - usableTop - pegHeight) * 0.62;
    if (pegTop < usableTop) pegTop = usableTop;

    this.geo = {
        w: w, h: h, s: s, center: center,
        top: pegTop, bottom: usableBottom, rowGap: rowGap,
        slotsHeight: slotsHeight, rows: rows
    };

    // pegRowY[r] ve her satırdaki peg matrisi. Satır r'de (r + 3) peg,
    // merkez etrafında; tek/çift satırlar yarım aralık kayar (staggered).
    this.pegRowY = [];
    for (var r = 0; r < rows; r++) {
        var pegsInRow = r + 3;
        var rowY = pegTop + rowGap * r;
        this.pegRowY.push(rowY);
        for (var c = 0; c < pegsInRow; c++) {
            var offset = (c - (pegsInRow - 1) / 2) * s;
            var peg = document.createElement("div");
            peg.className = "rd-peg";
            peg.style.left = (center + offset) + "px";
            peg.style.top = rowY + "px";
            this.board.insertBefore(peg, this.slotsEl);
            this.pegEls.push(peg);
        }
    }

    this.layoutSlots();
};

// Slotları en alt peg satırındaki boşluklara (gap) hizala.
Plinko.prototype.layoutSlots = function () {
    if (!this.geo || !this.slotEls) return;
    var g = this.geo;
    var N = this.slices.length;
    for (var j = 0; j < N; j++) {
        // gap j merkezi = merkez + (j - (N-1)/2) * s
        var cx = g.center + (j - (N - 1) / 2) * g.s;
        var el = this.slotEls[j];
        var margin = Math.max(g.s * 0.06, 1);
        el.style.left = (cx - g.s / 2 + margin) + "px";
        el.style.width = (g.s - margin * 2) + "px";
    }
};

// Kazanılamayan (kaybettiren) bir slot index'i döner: "pass" tipi ya da
// stokta olmayan dilim. Yoksa ortadaki dilime düşer.
Plinko.prototype.losingSlotIndex = function () {
    for (var i = 0; i < this.slices.length; i++) {
        var slice = this.slices[i];
        if (slice.type === "pass" || slice.is_available === false || !slice.code) {
            return i;
        }
    }
    return Math.floor(this.slices.length / 2);
};

// Belirli bir slotun x merkezi (topun ineceği hedef).
Plinko.prototype.slotCenterX = function (index) {
    var g = this.geo;
    var N = this.slices.length;
    return g.center + (index - (N - 1) / 2) * g.s;
};

Plinko.prototype.placeBall = function (x, y) {
    if (!this.board) return;
    if (!this.ball) {
        this.ball = document.createElement("div");
        this.ball.className = "rd-ball";
        this.board.insertBefore(this.ball, this.slotsEl);
    }
    var g = this.geo || { center: this.board.clientWidth / 2, top: this.board.clientHeight * 0.06, rowGap: 20 };
    var restY = Math.max(g.top * 0.35, g.top - (g.rowGap || 20));
    this.ball.style.left = (x !== undefined ? x : g.center) + "px";
    this.ball.style.top = (y !== undefined ? y : restY) + "px";
    // Beklerken hafif zıplama animasyonu (oyun hissi)
    if (!this.dropping && !this.finished) this.ball.classList.add("rd-ball-idle");
};

/* ------------------------------------------------------------------ */
/* Oyun akışı                                                          */
/* ------------------------------------------------------------------ */

Plinko.prototype.requestDrop = function () {
    if (this.dropping || this.finished) return;
    this.dropping = true;
    if (this.dropBtn) this.dropBtn.setAttribute("disabled", "true");
    if (this.ball) this.ball.classList.remove("rd-ball-idle");

    // Ses (kullanıcı etkileşimi sonrası AudioContext açılabilir)
    this.ensureAudio();
    if (this.soundEnabled && this.dropSoundUrl) this.playUrl(this.dropSoundUrl);

    if (Plinko.hasNativeBridge()) {
        // Native tarafına kazanan slotu sor. Native, window.choosePlinkoSlot ile cevap verir.
        Plinko.post({ method: "getPromotionCode" });
    } else {
        // Tarayıcıda lokal test: native'i taklit et, kazanan slotu kendimiz seçelim.
        this.simulateDrop();
    }
};

// Sadece lokal tarayıcı testi içindir. Native ortamda kullanılmaz.
Plinko.prototype.simulateDrop = function () {
    var self = this;
    var eligible = [];
    this.slices.forEach(function (slice, i) {
        // "pass" tipindeki ve stokta olmayan dilimler kazandırmaz; top oraya gitmez.
        if (slice.type !== "pass" && slice.code && slice.is_available !== false) {
            eligible.push({ index: i, code: slice.code });
        }
    });

    setTimeout(function () {
        if (eligible.length > 0) {
            var pick = eligible[Math.floor(Math.random() * eligible.length)];
            self.choose(pick.index, pick.code);
        } else {
            self.choose(-1, "");
        }
    }, 300);
};

// Native, kazanan slot index'ini ve promosyon kodunu bu fonksiyonla döner.
Plinko.prototype.choose = function (index, promotionCode) {
    var self = this;
    this.selectedIndex = index;
    this.selectedCode = promotionCode;

    if (index < 0 || index >= this.slices.length) {
        // Kazanan yok / stok tükendi: top kaybettiren ("pass") bir dilime düşsün,
        // yoksa ortadaki dilime.
        this.animateBall(this.losingSlotIndex(), function () {
            self.showSoldout();
        });
        return;
    }

    this.animateBall(index, function () {
        self.showResult(index, promotionCode);
    });
};

// Topu peglere çarptırarak hedef slota indirir.
// Galton board mantığı: R satır için tam olarak `targetIndex` kadar sağa,
// (R - targetIndex) kadar sola sapma yapılır; sıralama karıştırılır ki
// her seferinde farklı ama her zaman doğru slota inen bir yol oluşsun.
Plinko.prototype.animateBall = function (targetIndex, done) {
    var self = this;
    if (!this.board) { done(); return; }
    this.layoutPegs();
    var g = this.geo;
    var R = this.pegRows;
    var s = g.s;

    // Sapma dizisi: targetIndex adet +1 (sağ), kalanı -1 (sol), karıştırılmış.
    var t = Math.max(0, Math.min(targetIndex, R));
    var moves = [];
    var i;
    for (i = 0; i < t; i++) moves.push(1);
    for (i = t; i < R; i++) moves.push(-1);
    for (i = moves.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var tmp = moves[i]; moves[i] = moves[j]; moves[j] = tmp;
    }

    // Peg temas noktaları (waypoint). c: merkezden yarım-aralık biriminde ofset.
    var waypoints = [];
    var startY = g.top - (g.rowGap || 24);
    waypoints.push({ x: g.center, y: startY, peg: -1 });

    var c = 0; // row 0 pegi merkezde (c=0)
    for (var r = 0; r < R; r++) {
        waypoints.push({ x: g.center + c * s, y: self.pegRowY[r], peg: r });
        c += moves[r] * 0.5;
    }
    // Son iniş: hedef slot merkezi.
    var landX = self.slotCenterX(targetIndex);
    var landY = g.bottom + g.slotsHeight * 0.35;
    waypoints.push({ x: landX, y: landY, peg: -1 });

    self.placeBall(waypoints[0].x, waypoints[0].y);

    var segDur = 190;      // her satır arası süre (ms)
    var seg = 0;
    var segStart = null;
    var bounceH = Math.min(s * 0.5, 22);

    function easeInQuad(x) { return x * x; }
    function easeOutQuad(x) { return 1 - (1 - x) * (1 - x); }

    function frame(ts) {
        if (segStart === null) segStart = ts;
        var from = waypoints[seg];
        var to = waypoints[seg + 1];
        var lt = Math.min((ts - segStart) / segDur, 1);

        // Yatay: yumuşak geçiş. Dikey: yerçekimi hissi (hızlanan düşüş) +
        // pege çarpınca küçük sekme (parabolik yükselme).
        var x = from.x + (to.x - from.x) * easeOutQuad(lt);
        var y = from.y + (to.y - from.y) * easeInQuad(lt);
        var bounce = Math.sin(lt * Math.PI) * bounceH * (seg > 0 ? 1 : 0.3);
        y -= bounce;

        var scaleX = 1 + 0.18 * Math.sin(lt * Math.PI);
        var scaleY = 1 - 0.18 * Math.sin(lt * Math.PI);
        self.ball.style.left = x + "px";
        self.ball.style.top = y + "px";
        self.ball.style.transform = "translate(-50%,-50%) scale(" + scaleX.toFixed(3) + "," + scaleY.toFixed(3) + ")";

        self.spawnTrail(ts, x, y);

        if (lt < 1) {
            requestAnimationFrame(frame);
        } else {
            // Pege ulaşıldı: peg parlaması + top squash.
            if (to.peg >= 0) self.hitPeg(to.peg, to.x);
            self.ball.style.transform = "translate(-50%,-50%)";
            seg++;
            if (seg < waypoints.length - 1) {
                segStart = null;
                // son segmentte (slota iniş) biraz daha uzun ve serbest düşüş.
                segDur = (seg === waypoints.length - 2) ? 320 : 190;
                requestAnimationFrame(frame);
            } else {
                self.ball.style.left = landX + "px";
                self.ball.style.top = landY + "px";
                if (self.slotEls[targetIndex]) self.slotEls[targetIndex].classList.add("rd-win");
                // Kazanan bir dilimse kutlama efekti
                var winSlice = self.slices[targetIndex] || {};
                if (winSlice.type !== "pass" && winSlice.code) self.celebrate(targetIndex);
                setTimeout(done, 500);
            }
        }
    }
    requestAnimationFrame(frame);
};

// Belirli satırda, verilen x'e en yakın pegi bul ve çarpma efektini oynat.
Plinko.prototype.hitPeg = function (row, x) {
    if (!this.pegEls) return;
    var best = null, bestDist = Infinity;
    var startY = this.pegRowY[row];
    for (var i = 0; i < this.pegEls.length; i++) {
        var peg = this.pegEls[i];
        if (Math.abs(parseFloat(peg.style.top) - startY) > 1) continue;
        var d = Math.abs(parseFloat(peg.style.left) - x);
        if (d < bestDist) { bestDist = d; best = peg; }
    }
    if (best) {
        best.classList.remove("rd-hit");
        // reflow ile animasyonu yeniden tetikle
        void best.offsetWidth;
        best.classList.add("rd-hit");
    }
    // Çarpma sesi (özel drop_sound_url yoksa sentezle)
    if (!this.dropSoundUrl) this.playTick();
};

// Top düşerken arkasında kısa süre kalan parıltı izi bırakır.
Plinko.prototype.spawnTrail = function (ts, x, y) {
    if (this.p("ball_trail", "true") === "false") return;
    if (this._lastTrail && ts - this._lastTrail < 32) return;
    this._lastTrail = ts;
    var size = (this.ball ? this.ball.offsetWidth : 18) * 0.9;
    var dot = document.createElement("div");
    dot.className = "rd-trail";
    dot.style.width = size + "px";
    dot.style.height = size + "px";
    dot.style.left = x + "px";
    dot.style.top = y + "px";
    this.board.insertBefore(dot, this.slotsEl);
    setTimeout(function () {
        if (dot.parentNode) dot.parentNode.removeChild(dot);
    }, 500);
};

// Kazanma anında konfeti patlaması.
Plinko.prototype.celebrate = function (index) {
    if (this.p("confetti", "true") === "false") return;
    var board = this.board;
    if (!board) return;
    var w = board.clientWidth;
    var originX = (this.geo && typeof index === "number") ? this.slotCenterX(index) : w / 2;
    var colors = [];
    for (var s = 0; s < this.slices.length; s++) {
        if (this.slices[s].color) colors.push(this.slices[s].color);
    }
    colors.push(this.p("ball_color", "#ffd23f"));
    colors.push(this.p("button_color", "#ff477e"));
    colors.push("#ffffff");

    var count = 46;
    for (var i = 0; i < count; i++) {
        var piece = document.createElement("div");
        piece.className = "rd-confetti";
        var fromTop = Math.random() < 0.5;
        var startX = fromTop ? (Math.random() * w) : (originX + (Math.random() - 0.5) * 60);
        var startTop = fromTop ? -12 : (board.clientHeight * 0.8);
        piece.style.left = startX + "px";
        piece.style.top = startTop + "px";
        piece.style.background = colors[Math.floor(Math.random() * colors.length)];
        if (Math.random() < 0.4) piece.style.borderRadius = "50%";
        var cx = (Math.random() - 0.5) * 220;
        var cy = fromTop ? (board.clientHeight + 40) : -(board.clientHeight * 0.7 + Math.random() * 120);
        var cr = (Math.random() * 720 - 360);
        piece.style.setProperty("--rd-cx", cx.toFixed(0) + "px");
        piece.style.setProperty("--rd-cy", cy.toFixed(0) + "px");
        piece.style.setProperty("--rd-cr", cr.toFixed(0) + "deg");
        piece.style.animation = "rd-confetti-fall " + (1.1 + Math.random() * 0.9).toFixed(2) + "s cubic-bezier(0.2,0.7,0.3,1) " + (Math.random() * 0.25).toFixed(2) + "s forwards";
        board.insertBefore(piece, this.slotsEl);
        (function (el) {
            setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 2400);
        })(piece);
    }
};

Plinko.prototype.showResult = function (index, promotionCode) {
    var self = this;
    this.finished = true;
    var slice = this.slices[index] || {};
    var code = promotionCode || slice.code || "";

    // Kazanma sesi
    if (this.soundEnabled) {
        if (this.winSoundUrl) this.playUrl(this.winSoundUrl);
        else this.playWin();
    }

    this.overlay.innerHTML = "";

    var title = document.createElement("div");
    title.className = "rd-result-title";
    title.textContent = this.clean(this.actionData.promocode_title).replace(/<%PromotionCode%>/g, code);
    this.overlay.appendChild(title);

    if (slice.infotext) {
        var info = document.createElement("div");
        info.className = "rd-text";
        info.textContent = this.clean(slice.infotext);
        this.overlay.appendChild(info);
    }

    if (code) {
        var codeEl = document.createElement("div");
        codeEl.className = "rd-code";
        codeEl.textContent = code;
        this.overlay.appendChild(codeEl);
    }

    var copyFn = this.actionData.copybutton_function || "copy";
    var sliceLink = slice.ios_lnk || slice.android_lnk || "";

    var copyBtn = document.createElement("button");
    copyBtn.className = "rd-btn rd-copy";
    copyBtn.textContent = this.actionData.copybutton_label || "Copy";
    copyBtn.onclick = function () {
        Plinko.post({ method: "copyToClipboard", couponCode: code, sliceLink: sliceLink });
    };
    this.overlay.appendChild(copyBtn);

    if ((copyFn === "redirect" || copyFn === "copy_redirect") && this.actionData.redirectbutton_label) {
        var redirectBtn = document.createElement("button");
        redirectBtn.className = "rd-btn";
        redirectBtn.style.background = this.p("redirectbutton_color", this.p("button_color", "#ff477e"));
        redirectBtn.style.color = this.p("redirectbutton_text_color", "#ffffff");
        redirectBtn.textContent = this.actionData.redirectbutton_label;
        redirectBtn.onclick = function () {
            if (sliceLink) Plinko.post({ method: "openUrl", url: sliceLink });
        };
        this.overlay.appendChild(redirectBtn);
    }

    this.overlay.classList.add("rd-show");
};

Plinko.prototype.showSoldout = function () {
    this.finished = true;
    this.overlay.innerHTML = "";
    var msg = document.createElement("div");
    msg.className = "rd-soldout";
    msg.textContent = this.clean(this.actionData.promocodes_soldout_message);
    this.overlay.appendChild(msg);
    this.overlay.classList.add("rd-show");
};

/* ------------------------------------------------------------------ */
/* Küçük yardımcılar                                                   */
/* ------------------------------------------------------------------ */

Plinko.prototype.clearContent = function () {
    if (!this.root) return;
    var kids = Array.prototype.slice.call(this.root.children);
    for (var i = 0; i < kids.length; i++) {
        var cls = kids[i].className || "";
        // Üst buton çubuğunu ve yardım katmanını koru
        if (cls.indexOf("rd-topbar") !== -1 || cls.indexOf("rd-help") !== -1) continue;
        this.root.removeChild(kids[i]);
    }
};

/* ------------------------------------------------------------------ */
/* Ses (Web Audio ile sentezlenir; istenirse özel URL ile de çalar)    */
/* ------------------------------------------------------------------ */

Plinko.prototype.ensureAudio = function () {
    if (!this.soundEnabled) return;
    try {
        if (!this.audioCtx) {
            var AC = window.AudioContext || window.webkitAudioContext;
            if (AC) this.audioCtx = new AC();
        }
        if (this.audioCtx && this.audioCtx.state === "suspended") {
            this.audioCtx.resume();
        }
    } catch (e) { /* ses desteklenmiyor olabilir */ }
};

// Topun bir çiviye çarpma sesi (kısa "tık")
Plinko.prototype.playTick = function () {
    if (!this.soundEnabled || !this.audioCtx) return;
    var now = this.audioCtx.currentTime;
    // çok sık tetiklenmesini engelle
    if (now - this._lastTick < 0.03) return;
    this._lastTick = now;
    try {
        var ctx = this.audioCtx;
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.type = "triangle";
        osc.frequency.value = 520 + Math.random() * 480;
        gain.gain.setValueAtTime(0.0001, now);
        gain.gain.exponentialRampToValueAtTime(0.14, now + 0.005);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.08);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.09);
    } catch (e) {}
};

// Kazanma melodisi (kısa arpej)
Plinko.prototype.playWin = function () {
    if (!this.audioCtx) { this.ensureAudio(); }
    if (!this.audioCtx) return;
    try {
        var ctx = this.audioCtx;
        var notes = [523.25, 659.25, 783.99, 1046.5]; // C5 E5 G5 C6
        for (var i = 0; i < notes.length; i++) {
            var start = ctx.currentTime + i * 0.12;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = "sine";
            osc.frequency.value = notes[i];
            gain.gain.setValueAtTime(0.0001, start);
            gain.gain.exponentialRampToValueAtTime(0.2, start + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.35);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(start);
            osc.stop(start + 0.36);
        }
    } catch (e) {}
};

// Panelden verilen özel ses dosyasını çalar
Plinko.prototype.playUrl = function (url) {
    if (!this.soundEnabled || !url) return;
    try {
        var a = new Audio(url);
        a.play().catch(function () {});
    } catch (e) {}
};

Plinko.prototype.toggleSound = function () {
    this.soundEnabled = !this.soundEnabled;
    if (this.soundEnabled) this.ensureAudio();
    this.updateSoundIcon();
};

Plinko.prototype.updateSoundIcon = function () {
    if (!this.soundBtn) return;
    var on = "<svg width='20' height='20' viewBox='0 0 24 24' fill='currentColor'><path d='M3 9v6h4l5 5V4L7 9H3z'/><path d='M16.5 8.5a4.5 4.5 0 0 1 0 7' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round'/></svg>";
    var off = "<svg width='20' height='20' viewBox='0 0 24 24' fill='currentColor'><path d='M3 9v6h4l5 5V4L7 9H3z'/><line x1='16' y1='9.5' x2='22' y2='14.5' stroke='currentColor' stroke-width='2' stroke-linecap='round'/><line x1='22' y1='9.5' x2='16' y2='14.5' stroke='currentColor' stroke-width='2' stroke-linecap='round'/></svg>";
    this.soundBtn.innerHTML = this.soundEnabled ? on : off;
};

/* ------------------------------------------------------------------ */
/* "?" Yardım katmanı                                                  */
/* ------------------------------------------------------------------ */

Plinko.prototype.buildHelpOverlay = function () {
    var self = this;
    var help = document.createElement("div");
    help.className = "rd-help";
    this.helpEl = help;

    var title = document.createElement("div");
    title.className = "rd-help-title";
    title.textContent = this.p("help_title", this.content.how_to_play_title || "Nasıl Oynanır?");
    help.appendChild(title);

    var text = document.createElement("div");
    text.className = "rd-help-text";
    var defaultText = "Topu bırakmak için alttaki butona bas.\nTop, çivilere çarparak aşağı iner ve en alttaki dilimlerden birine düşer.\nTopun düştüğü dilimdeki ödülü kazanırsın!";
    text.textContent = this.clean(this.p("help_text", this.content.how_to_play || defaultText));
    help.appendChild(text);

    var btn = document.createElement("button");
    btn.className = "rd-btn rd-help-close";
    btn.textContent = this.p("help_close_label", this.content.how_to_play_close || "Anladım");
    btn.onclick = function () { self.toggleHelp(false); };
    help.appendChild(btn);

    // arka plana tıklayınca da kapansın
    help.addEventListener("click", function (e) {
        if (e.target === help) self.toggleHelp(false);
    });

    this.root.appendChild(help);
};

Plinko.prototype.toggleHelp = function (show) {
    if (!this.helpEl) return;
    var willShow = (show === undefined) ? !this.helpEl.classList.contains("rd-show") : show;
    if (willShow) this.helpEl.classList.add("rd-show");
    else this.helpEl.classList.remove("rd-show");
};

Plinko.prototype.isValidEmail = function (email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

Plinko.prototype.linkify = function (text, url) {
    var safe = this.clean(text);
    if (url) {
        return safe.replace(/<LINK>(.*?)<\/LINK>/g, "<a href='" + url + "' target='_blank'>$1</a>");
    }
    return safe.replace(/<\/?LINK>/g, "");
};
