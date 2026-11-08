package com.mdfitsrq.mdfit

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.webkit.*
import android.widget.Button
import android.widget.LinearLayout
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import org.json.JSONObject

/** The member app in a WebView, behaving like a native app: inline video, pull to refresh, native dialogs,
 *  links outside mymdfit.com in a Custom Tab, notification taps and shortcuts routed to the right tab. */
class MainActivity : AppCompatActivity() {
    private lateinit var web: WebView
    private lateinit var refresh: SwipeRefreshLayout
    private lateinit var offline: LinearLayout
    private lateinit var bridge: NativeBridge
    private var loadedOnce = false
    private var pendingRoute: String? = null
    private var keepSplash = true
    private var bridgeScript = ""

    private val askNotifications = registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) Push.refreshToken(this)
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen().setKeepOnScreenCondition { keepSplash }
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        web = findViewById(R.id.web)
        refresh = findViewById(R.id.refresh)
        offline = findViewById(R.id.offline)
        bridge = NativeBridge(this, web)

        with(web.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            mediaPlaybackRequiresUserGesture = false      // the workout player auto-advances to the next clip
            allowFileAccess = false
            setSupportMultipleWindows(true)
            // A normal Chrome user agent (the site's bot filter blocks unknown clients) plus an app marker
            userAgentString = userAgentString.replace("; wv", "") + " MDFitApp-Android/1.0"
        }
        if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING))
            WebSettingsCompat.setAlgorithmicDarkeningAllowed(web.settings, false)   // the site has its own dark design
        web.setBackgroundColor(ContextCompat.getColor(this, R.color.mdfit_navy))
        web.addJavascriptInterface(bridge, "mdfitAndroid")
        // The same bridge script as iOS, run before the page's own scripts
        bridgeScript = assets.open("bridge.js").bufferedReader().use { it.readText() }
        if (WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT))
            WebViewCompat.addDocumentStartJavaScript(web, bridgeScript, SITE_HOSTS.map { "https://$it" }.toSet())
        web.webViewClient = Client()
        web.webChromeClient = Chrome()
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, true)   // Stripe checkout, Cal.com embeds

        refresh.setColorSchemeColors(ContextCompat.getColor(this, R.color.mdfit_gold))
        refresh.setProgressBackgroundColorSchemeColor(ContextCompat.getColor(this, R.color.mdfit_navy))
        refresh.setOnRefreshListener { if (web.url == null) web.loadUrl(HOME) else web.reload() }
        // Only pull to refresh when the page itself is scrolled to the top
        refresh.setOnChildScrollUpCallback { _, _ -> web.scrollY > 0 }

        findViewById<Button>(R.id.retry).setOnClickListener { offline.visibility = View.GONE; if (web.url == null) web.loadUrl(HOME) else web.reload() }
        findViewById<Button>(R.id.call).setOnClickListener { startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:9413130562"))) }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() { if (web.canGoBack()) web.goBack() else { isEnabled = false; onBackPressedDispatcher.onBackPressed() } }
        })

        if (savedInstanceState == null) web.loadUrl(HOME) else web.restoreState(savedInstanceState)
        handleIntent(intent)
        Push.refreshToken(this)
    }

    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); handleIntent(intent) }

    override fun onResume() { super.onResume(); web.onResume() }
    override fun onPause() { super.onPause(); web.onPause() }
    override fun onSaveInstanceState(outState: Bundle) { super.onSaveInstanceState(outState); web.saveState(outState) }

    private fun handleIntent(intent: Intent?) {
        intent?.getStringExtra("route")?.let { intent.removeExtra("route"); open(it) }
        // App link https://www.mymdfit.com/...
        intent?.data?.let { if (intent.action == Intent.ACTION_VIEW && isSite(it)) { intent.data = null; web.loadUrl(it.toString()) } }
        // Back from a payment: mdfit://checkout?to=/account?checkout=success…
        intent?.data?.let {
            if (it.scheme == "mdfit" && it.host == "checkout") {
                var to = it.getQueryParameter("to") ?: "/account#premium"; intent.data = null
                if (!to.startsWith("/") || to.startsWith("//")) to = "/account#premium"
                web.loadUrl("https://www.mymdfit.com$to")
            }
        }
    }

    /** Opens a tab of the member app ("generate", "messages/dr") or Admin ("admin", "admin/messages"). */
    fun open(route: String) {
        val hash = route.lowercase().filter { it.isLetterOrDigit() || it == '/' || it == '-' }
        if (!loadedOnce) { pendingRoute = hash; return }
        val admin = hash.startsWith("admin")
        val page = if (admin) "/admin" else "/account"
        val tab = if (admin) hash.removePrefix("admin").trimStart('/') else hash
        val current = web.url?.let { Uri.parse(it) }
        if (current != null && isSite(current) && current.path?.startsWith(page) == true) web.evaluateJavascript("location.hash='#$tab'", null)
        else web.loadUrl("https://www.mymdfit.com$page#$tab")
    }

    /** Called by Push when Firebase hands over the device token. */
    fun deliverDeviceToken(token: String) {
        if (loadedOnce) web.evaluateJavascript("window.MDFitNative && MDFitNative.setDeviceToken(${JSONObject.quote(token)})", null)
    }

    fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
            askNotifications.launch(Manifest.permission.POST_NOTIFICATIONS)
        else Push.refreshToken(this)
    }

    /** Stripe Checkout / billing portal in a Chrome Custom Tab (Google Pay works there); returns via mdfit://checkout */
    fun openCheckout(url: Uri) = openOutside(url)

    private fun openOutside(url: Uri) {
        try {
            CustomTabsIntent.Builder()
                .setDefaultColorSchemeParams(CustomTabColorSchemeParams.Builder().setToolbarColor(ContextCompat.getColor(this, R.color.mdfit_navy)).build())
                .setShowTitle(true).build().launchUrl(this, url)
        } catch (_: Exception) { try { startActivity(Intent(Intent.ACTION_VIEW, url)) } catch (_: Exception) {} }
    }

    private inner class Client : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            val url = request.url
            when (url.scheme?.lowercase()) {
                "tel", "mailto", "sms", "geo", "smsto" -> { try { startActivity(Intent(Intent.ACTION_VIEW, url)) } catch (_: Exception) {}; return true }
                "blob", "data", "about", "javascript" -> return false
                "http" -> { openOutside(url); return true }
            }
            if (!request.isForMainFrame) return false          // embedded frames (Stripe, Cal.com, players) load in place
            if (isSite(url)) return false
            openOutside(url)                                    // Google Maps, Stripe portal, Instagram...
            return true
        }

        override fun onPageStarted(view: WebView, url: String?, favicon: Bitmap?) {
            offline.visibility = View.GONE
            // Older WebViews without document-start scripts: inject as early as possible instead
            if (!WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT) && url != null && isSite(Uri.parse(url)))
                view.evaluateJavascript(bridgeScript, null)
        }

        override fun onPageFinished(view: WebView, url: String?) {
            refresh.isRefreshing = false
            keepSplash = false
            if (!loadedOnce) { loadedOnce = true; pendingRoute?.let { pendingRoute = null; open(it) } }
            Push.lastToken?.let { deliverDeviceToken(it) }
            val path = url?.let { Uri.parse(it).path } ?: ""
            if (isSite(Uri.parse(url ?: "")) && (path.startsWith("/account") || path.startsWith("/admin")))
                web.postDelayed({ Reminders.askOnce(this@MainActivity) }, 4000)   // signed in: ask once to allow notifications
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            if (!request.isForMainFrame) return
            refresh.isRefreshing = false
            keepSplash = false
            offline.visibility = View.VISIBLE
        }

        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean { view.reload(); return true }
    }

    private inner class Chrome : WebChromeClient() {
        // target=_blank / window.open: same-site in this view, everything else in a Custom Tab
        override fun onCreateWindow(view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: android.os.Message): Boolean {
            val href = view.hitTestResult.extra ?: return false
            val url = Uri.parse(href)
            if (isSite(url)) view.loadUrl(href) else openOutside(url)
            return false
        }
        override fun onJsAlert(view: WebView, url: String, message: String, result: JsResult): Boolean {
            AlertDialog.Builder(this@MainActivity).setMessage(message).setPositiveButton(android.R.string.ok) { _, _ -> result.confirm() }
                .setOnCancelListener { result.confirm() }.show(); return true
        }
        override fun onJsConfirm(view: WebView, url: String, message: String, result: JsResult): Boolean {
            AlertDialog.Builder(this@MainActivity).setMessage(message).setPositiveButton(android.R.string.ok) { _, _ -> result.confirm() }
                .setNegativeButton(android.R.string.cancel) { _, _ -> result.cancel() }.setOnCancelListener { result.cancel() }.show(); return true
        }
        override fun onJsPrompt(view: WebView, url: String, message: String, defaultValue: String?, result: JsPromptResult): Boolean {
            val input = android.widget.EditText(this@MainActivity).apply { setText(defaultValue ?: "") }
            AlertDialog.Builder(this@MainActivity).setMessage(message).setView(input)
                .setPositiveButton(android.R.string.ok) { _, _ -> result.confirm(input.text.toString()) }
                .setNegativeButton(android.R.string.cancel) { _, _ -> result.cancel() }.setOnCancelListener { result.cancel() }.show(); return true
        }
    }

    companion object {
        const val HOME = "https://www.mymdfit.com/account"
        val SITE_HOSTS = setOf("www.mymdfit.com", "mymdfit.com")
        fun isSite(url: Uri) = url.host?.lowercase() in SITE_HOSTS
    }
}
