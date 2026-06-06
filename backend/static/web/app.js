const state = {
  lang: localStorage.getItem("codeva_lang") || "fr",
  user: JSON.parse(localStorage.getItem("codeva_user") || "null"),
  view: "login",
};

const API_BASE =
  window.CODEVA_API_BASE ||
  (["localhost", "127.0.0.1"].includes(window.location.hostname)
    ? "https://codeva-backend-a2ny.onrender.com"
    : "");
let activeQrScanner = null;

const copy = {
  fr: {
    title: "Presence QR System",
    sub: "Attendance via QR code",
    login: "Connexion",
    email: "Email",
    password: "Mot de passe",
    forgot: "Mot de passe oublie ?",
    noAccount: "Pas de compte ?",
    create: "Creer un compte",
    pending: "Compte en attente de validation",
    fullName: "Nom complet",
    phone: "Telephone",
    job: "Fonction",
    otp: "Code de verification",
    sendOtp: "Envoyer le code",
    register: "Creer",
    reset: "Reinitialiser",
    newPassword: "Nouveau mot de passe",
    currentPassword: "Mot de passe actuel",
    changePassword: "Changer le mot de passe",
    home: "Accueil",
    attendance: "Presences",
    scan: "Scanner QR code",
    registerAttendance: "Enregistrer la presence",
    history: "Historique",
    dashboard: "Dashboard Admin",
    requests: "Demandes",
    users: "Utilisateurs",
    todayQr: "QR du jour",
    locations: "Localisations",
    companySite: "Site entreprise",
    reports: "Rapports",
    stats: "Statistiques",
    developer: "Espace developpeur",
    companies: "Entreprises",
    add: "Ajouter",
    save: "Enregistrer",
    logout: "Sortir",
    back: "Retour",
    approve: "Valider",
    reject: "Refuser",
    active: "Active",
    frozen: "Frozen",
    present: "Present",
    absent: "Absent",
    month: "Mois",
    group: "Groupe",
    all: "Tous",
    empty: "Aucun enregistrement",
    search: "Rechercher nom ou email",
    latitude: "Latitude",
    longitude: "Longitude",
    radius: "Rayon autorise en metres",
    usePosition: "Utiliser ma position actuelle",
    mapLink: "Lien Google Maps",
    token: "Token",
    workerPassword: "Mot de passe temporaire",
    workerAdded: "Employe ajoute",
    cameraUnavailable: "Camera indisponible",
    scanHint: "Placez le QR code devant la camera",
  },
  ar: {
    title: "نظام الحضور بالرمز",
    sub: "الحضور عبر رمز QR",
    login: "تسجيل الدخول",
    email: "البريد الإلكتروني",
    password: "كلمة المرور",
    forgot: "نسيت كلمة المرور؟",
    noAccount: "لا تملك حساباً؟",
    create: "إنشاء حساب",
    pending: "الحساب قيد التحقق",
    fullName: "الاسم الكامل",
    phone: "الهاتف",
    job: "الوظيفة",
    otp: "رمز التحقق",
    sendOtp: "إرسال الرمز",
    register: "إنشاء",
    reset: "إعادة التعيين",
    newPassword: "كلمة مرور جديدة",
    currentPassword: "كلمة المرور الحالية",
    changePassword: "تغيير كلمة المرور",
    home: "الرئيسية",
    attendance: "الحضور",
    scan: "مسح QR code",
    registerAttendance: "تسجيل الحضور",
    history: "السجل",
    dashboard: "لوحة التحكم",
    requests: "الطلبات",
    users: "المستخدمون",
    todayQr: "رمز اليوم",
    locations: "المواقع",
    companySite: "موقع الشركة",
    reports: "التقارير",
    stats: "إحصائيات",
    developer: "لوحة المطور",
    companies: "الشركات",
    add: "إضافة",
    save: "حفظ",
    logout: "خروج",
    back: "رجوع",
    approve: "اعتماد",
    reject: "رفض",
    active: "نشطة",
    frozen: "مجمّدة",
    present: "حاضر",
    absent: "غائب",
    month: "الشهر",
    group: "المجموعة",
    all: "الكل",
    empty: "لا سجلات",
    search: "ابحث بالاسم أو البريد",
    latitude: "خط العرض",
    longitude: "خط الطول",
    radius: "النطاق بالمتر",
    usePosition: "استخدم موقعي الحالي",
    mapLink: "رابط Google Maps",
    token: "الرمز",
    workerPassword: "كلمة مرور مؤقتة",
    workerAdded: "تمت إضافة العامل",
    cameraUnavailable: "الكاميرا غير متاحة",
    scanHint: "ضع رمز QR أمام الكاميرا",
  },
  en: {
    title: "Presence QR System",
    sub: "Attendance via QR code",
    login: "Login",
    email: "Email",
    password: "Password",
    forgot: "Forgot password?",
    noAccount: "No account?",
    create: "Create account",
    pending: "Account pending approval",
    fullName: "Full name",
    phone: "Phone",
    job: "Role",
    otp: "Verification code",
    sendOtp: "Send code",
    register: "Create",
    reset: "Reset",
    newPassword: "New password",
    currentPassword: "Current password",
    changePassword: "Change password",
    home: "Home",
    attendance: "Attendance",
    scan: "Scan QR code",
    registerAttendance: "Register attendance",
    history: "History",
    dashboard: "Admin Dashboard",
    requests: "Requests",
    users: "Users",
    todayQr: "Today QR",
    locations: "Locations",
    companySite: "Company site",
    reports: "Reports",
    stats: "Statistics",
    developer: "Developer",
    companies: "Companies",
    add: "Add",
    save: "Save",
    logout: "Logout",
    back: "Back",
    approve: "Approve",
    reject: "Reject",
    active: "Active",
    frozen: "Frozen",
    present: "Present",
    absent: "Absent",
    month: "Month",
    group: "Group",
    all: "All",
    empty: "No records",
    search: "Search name or email",
    latitude: "Latitude",
    longitude: "Longitude",
    radius: "Allowed radius in meters",
    usePosition: "Use my current position",
    mapLink: "Google Maps link",
    token: "Token",
    workerPassword: "Temporary password",
    workerAdded: "Worker added",
    cameraUnavailable: "Camera unavailable",
    scanHint: "Place the QR code in front of the camera",
  },
};

const t = (key) => copy[state.lang][key] || copy.fr[key] || key;
const app = document.getElementById("app");

function api(path, options = {}) {
  return fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(state.user?.email ? {"X-User-Email": state.user.email} : {}),
      ...(options.headers || {}),
    },
  }).then(async (response) => {
    const data = await response.json().catch(() => ({}));
    if (!response.ok && data.ok !== true) data.__status = response.status;
    return data;
  });
}

function setUser(user) {
  state.user = user;
  if (user) localStorage.setItem("codeva_user", JSON.stringify(user));
  else localStorage.removeItem("codeva_user");
}

function field(name, label, type = "text", value = "") {
  return `<div class="field"><label for="${name}">${label}</label><input id="${name}" name="${name}" type="${type}" value="${escapeHtml(value)}"></div>`;
}

function selectField(name, label, options, value = "") {
  return `<div class="field"><label for="${name}">${label}</label><select id="${name}" name="${name}">${options.map((item) => `<option value="${item.value}" ${item.value === value ? "selected" : ""}>${item.label}</option>`).join("")}</select></div>`;
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[char]));
}

function authLayout(title, body, message = "") {
  document.documentElement.lang = state.lang;
  document.documentElement.dir = state.lang === "ar" ? "rtl" : "ltr";
  app.innerHTML = `
    <main class="auth-shell">
      <section class="auth-panel">
        <div class="topbar">${state.view === "login" ? "<span></span>" : `<button class="icon-btn" data-view="login" title="${t("back")}">‹</button>`}<span></span></div>
        <div class="brand"><h1>${t("title")}</h1><p>${t("sub")}</p></div>
        <form class="auth-card" id="authForm">
          <h2 class="card-title">${title}</h2>
          ${body}
          ${message ? `<div class="message ${message.startsWith("!") ? "error" : "ok"}">${escapeHtml(message.replace(/^!/, ""))}</div>` : ""}
        </form>
        <div class="lang-row">
          ${["ar", "fr", "en"].map((lang) => `<button data-lang="${lang}" class="${state.lang === lang ? "active" : ""}">${lang.toUpperCase()}</button>`).join("")}
        </div>
      </section>
    </main>`;
}

function renderLogin(message = "") {
  state.view = "login";
  authLayout(t("login"), `
    ${field("email", t("email"), "email")}
    ${field("password", t("password"), "password")}
    <div class="link-row"><button type="button" class="text-link" data-view="forgot">${t("forgot")}</button><button type="button" class="text-link" data-view="change">${t("changePassword")}</button></div>
    <button class="primary-btn full" type="submit">${t("login")}</button>
    <p style="margin:12px 0 0;text-align:center;font-size:12px;opacity:.72">${t("pending")}</p>`, message);
  document.getElementById("authForm").onsubmit = login;
}

async function login(event) {
  event.preventDefault();
  const body = formData(event.currentTarget);
  const data = await api("/auth/login", {method: "POST", body: JSON.stringify(body)});
  if (data.ok !== true) return renderLogin("!" + reasonText(data.reason));
  setUser(data.user);
  routeForRole();
}

function renderSignup(message = "") {
  state.view = "signup";
  authLayout(t("create"), `
    ${field("fullName", t("fullName"))}
    ${field("email", t("email"), "email")}
    ${field("phone", t("phone"))}
    ${field("jobTitle", t("job"))}
    ${field("password", t("password"), "password")}
    ${field("otp", t("otp"))}
    <div class="actions"><button class="secondary-btn" type="button" id="sendOtp">${t("sendOtp")}</button><button class="primary-btn" type="submit">${t("register")}</button></div>`, message);
  document.getElementById("sendOtp").onclick = requestOtp;
  document.getElementById("authForm").onsubmit = signup;
}

async function requestOtp() {
  const email = document.getElementById("email")?.value.trim();
  if (!email) return renderSignup("!" + t("email"));
  const data = await api("/auth/request-otp", {method: "POST", body: JSON.stringify({email, purpose: state.view === "signup" ? "register" : "login"})});
  const msg = data.ok ? `${t("otp")} ${data.code ? data.code : ""}` : "!" + reasonText(data.reason);
  state.view === "signup" ? renderSignup(msg) : renderForgot(msg);
}

async function signup(event) {
  event.preventDefault();
  const data = await api("/auth/register", {method: "POST", body: JSON.stringify(formData(event.currentTarget))});
  if (data.ok !== true) return renderSignup("!" + reasonText(data.reason));
  renderLogin(t("pending"));
}

function renderForgot(message = "") {
  state.view = "forgot";
  authLayout(t("forgot"), `
    ${field("email", t("email"), "email")}
    ${field("code", t("otp"))}
    ${field("newPassword", t("newPassword"), "password")}
    <div class="actions"><button class="secondary-btn" type="button" id="sendOtp">${t("sendOtp")}</button><button class="primary-btn" type="submit">${t("reset")}</button></div>`, message);
  document.getElementById("sendOtp").onclick = requestOtp;
  document.getElementById("authForm").onsubmit = async (event) => {
    event.preventDefault();
    const data = await api("/auth/reset-password", {method: "POST", body: JSON.stringify(formData(event.currentTarget))});
    data.ok ? renderLogin(t("reset")) : renderForgot("!" + reasonText(data.reason));
  };
}

function renderChange(message = "") {
  state.view = "change";
  authLayout(t("changePassword"), `
    ${field("email", t("email"), "email")}
    ${field("oldPassword", t("currentPassword"), "password")}
    ${field("newPassword", t("newPassword"), "password")}
    <button class="primary-btn full" type="submit">${t("save")}</button>`, message);
  document.getElementById("authForm").onsubmit = async (event) => {
    event.preventDefault();
    const data = await api("/auth/change-password", {method: "POST", body: JSON.stringify(formData(event.currentTarget))});
    data.ok ? renderLogin(t("save")) : renderChange("!" + reasonText(data.reason));
  };
}

function appLayout(title, content, dark = false) {
  if (activeQrScanner) {
    activeQrScanner.stop().catch(() => {});
    activeQrScanner = null;
  }
  document.documentElement.dir = state.lang === "ar" ? "rtl" : "ltr";
  app.innerHTML = `
    <main class="app-shell">
      <header class="app-header ${dark ? "dark" : ""}">
        <button class="icon-btn" data-action="home" title="${t("home")}">⌂</button>
        <div><h1>${title}</h1><p>${escapeHtml(state.user?.email || "")}</p></div>
        <div class="spacer"></div>
        <button class="icon-btn" data-action="logout" title="${t("logout")}">↩</button>
      </header>
      <section class="screen">${content}</section>
    </main>`;
}

function routeForRole() {
  if (!state.user) return renderLogin();
  if (state.user.role === "developer") return renderDeveloper();
  if (state.user.role === "admin") return renderAdmin();
  return renderUserHome();
}

function renderUserHome(message = "") {
  appLayout(t("home"), `
    <div class="panel">
      <div class="worker-actions">
        <button class="primary-btn worker-btn" id="byQr">${t("scan")}</button>
        <button class="secondary-btn worker-btn" id="byLocation">${t("registerAttendance")}</button>
      </div>
      ${message ? `<div class="message ${message.startsWith("!") ? "error" : "ok"}">${escapeHtml(message.replace(/^!/, ""))}</div>` : ""}
    </div>`);
  document.getElementById("byLocation").onclick = recordLocation;
  document.getElementById("byQr").onclick = renderWorkerScanner;
}

async function recordLocation() {
  if (!navigator.geolocation) return renderUserHome("!GPS");
  navigator.geolocation.getCurrentPosition(async (pos) => {
    const data = await api("/attendance/location", {method: "POST", body: JSON.stringify({email: state.user.email, latitude: pos.coords.latitude, longitude: pos.coords.longitude})});
    renderUserHome(data.verified || data.already ? t("present") : "!" + `${t("absent")} ${Math.round(data.distanceMeters || 0)}m`);
  }, () => renderUserHome("!Permission de localisation refusee"), {enableHighAccuracy: true, timeout: 20000});
}

async function scanQrToken(token) {
  const data = await api("/attendance/scan", {method: "POST", body: JSON.stringify({email: state.user.email, token})});
  renderUserHome(data.ok ? t("present") : "!" + reasonText(data.reason));
}

function renderWorkerScanner() {
  appLayout(t("scan"), `
    <div class="panel">
      <p class="scan-hint">${t("scanHint")}</p>
      <div id="qrReader"></div>
      <div class="actions scanner-actions">
        <button class="secondary-btn" data-action="home">${t("back")}</button>
      </div>
    </div>`);
  startQrCamera();
}

async function startQrCamera() {
  const reader = document.getElementById("qrReader");
  if (!window.Html5Qrcode || !reader) {
    renderUserHome("!" + t("cameraUnavailable"));
    return;
  }
  const scanner = new Html5Qrcode("qrReader");
  activeQrScanner = scanner;
  try {
    await scanner.start(
      {facingMode: "environment"},
      {fps: 10, qrbox: {width: 240, height: 240}},
      async (decodedText) => {
        await scanner.stop().catch(() => {});
        activeQrScanner = null;
        await scanQrToken(decodedText.trim());
      },
    );
  } catch (_) {
    renderUserHome("!" + t("cameraUnavailable"));
  }
}

function renderAdmin() {
  appLayout(t("dashboard"), `<div class="nav-grid">
    ${navCard("requests", t("requests"), t("approve"), "👤", "#3b82f6")}
    ${navCard("attendance", t("attendance"), t("present"), "✓", "#22c55e")}
    ${navCard("qr", t("todayQr"), t("token"), "▣", "#f59e0b")}
    ${navCard("locations", t("locations"), t("mapLink"), "⌖", "#06b6d4")}
    ${navCard("site", t("companySite"), t("save"), "⌂", "#0f766e")}
    ${navCard("reports", t("reports"), t("month"), "▤", "#14b8a6")}
    ${navCard("stats", t("stats"), t("attendance"), "↗", "#22c55e")}
  </div>`);
}

function navCard(view, title, sub, symbol, color) {
  return `<button class="nav-card" data-admin="${view}" style="background:${color}"><span class="symbol">${symbol}</span><span><strong>${title}</strong><span>${sub}</span></span></button>`;
}

async function renderRequests() {
  appLayout(t("requests"), `
    <form class="panel light-form" id="addWorkerForm">
      <h2>${t("add")} ${t("users")}</h2>
      <div class="toolbar">
        ${field("fullName", t("fullName"))}
        ${field("email", t("email"), "email")}
        ${field("phone", t("phone"))}
        ${field("jobTitle", t("job"))}
        ${field("password", t("workerPassword"), "text", "Temp1234")}
        <button class="primary-btn" type="submit">${t("add")}</button>
      </div>
      <div id="addWorkerMessage"></div>
    </form>
    <div class="toolbar light-form">${field("search", t("search"))}</div>
    <div id="users" class="stack"></div>`);
  document.getElementById("addWorkerForm").onsubmit = addWorker;
  document.getElementById("search").oninput = loadUsers;
  await loadUsers();
}

async function loadUsers() {
  const query = (document.getElementById("search")?.value || "").toLowerCase();
  const statuses = ["pending", "approved", "rejected"];
  const chunks = await Promise.all(statuses.map((status) => api(`/admin/users?status=${status}&actorEmail=${encodeURIComponent(state.user.email)}`).then((data) => (data.users || []).map((u) => ({...u, status})))));
  const rows = chunks.flat().filter((u) => (`${u.fullName} ${u.email}`).toLowerCase().includes(query));
  document.getElementById("users").innerHTML = rows.length ? rows.map(userRow).join("") : `<p>${t("empty")}</p>`;
}

function userRow(user) {
  return `<div class="list-item"><div class="main"><strong>${escapeHtml(user.fullName)}</strong><small>${escapeHtml(user.email)} · ${escapeHtml(user.jobTitle || "")}</small></div><span class="badge ${user.status === "approved" ? "ok" : user.status === "rejected" ? "bad" : ""}">${user.status}</span><div class="actions"><button class="secondary-btn" data-approve="${user.id}">${t("approve")}</button><button class="danger-btn" data-reject="${user.id}">${t("reject")}</button></div></div>`;
}

async function addWorker(event) {
  event.preventDefault();
  const body = formData(event.currentTarget);
  const message = document.getElementById("addWorkerMessage");
  const data = await api("/auth/register", {
    method: "POST",
    body: JSON.stringify({
      ...body,
      role: "worker",
      status: "approved",
      actorEmail: state.user.email,
    }),
  });
  if (message) {
    message.innerHTML = `<div class="message ${data.ok ? "ok" : "error"}">${escapeHtml(data.ok ? t("workerAdded") : reasonText(data.reason))}</div>`;
  }
  if (data.ok) event.currentTarget.reset();
  loadUsers();
}

async function renderAttendance() {
  const month = monthToken(new Date());
  appLayout(t("attendance"), `<div class="toolbar light-form">${field("month", t("month"), "month", month)}${selectField("group", t("group"), [{value:"", label:t("all")},{value:"Groupe A", label:"Groupe A"},{value:"Groupe B", label:"Groupe B"}])}<button class="primary-btn" id="reload">${t("save")}</button></div><div id="attendanceRows" class="stack"></div>`);
  document.getElementById("reload").onclick = loadAttendance;
  document.getElementById("month").onchange = loadAttendance;
  document.getElementById("group").onchange = loadAttendance;
  await loadAttendance();
}

async function loadAttendance() {
  const month = document.getElementById("month").value || monthToken(new Date());
  const group = document.getElementById("group").value;
  const data = await api(`/attendance/list?month=${encodeURIComponent(month)}&group=${encodeURIComponent(group)}&actorEmail=${encodeURIComponent(state.user.email)}`);
  const rows = data.items || [];
  document.getElementById("attendanceRows").innerHTML = rows.length ? rows.map((item) => `<div class="list-item"><div class="main"><strong>${escapeHtml(item.name)}</strong><small>${escapeHtml(item.group || "")} · ${escapeHtml(item.date || "")} · ${escapeHtml(item.time || "")}</small></div><span class="badge ${item.status === "present" ? "ok" : "bad"}">${item.status === "present" ? t("present") : t("absent")}</span></div>`).join("") : `<p>${t("empty")}</p>`;
}

async function renderQr() {
  appLayout(t("todayQr"), `<div class="panel"><div id="qrBox"></div><p style="text-align:center"><b id="qrToken"></b></p></div>`);
  const data = await api("/qr/today");
  document.getElementById("qrToken").textContent = data.token || "";
  const box = document.getElementById("qrBox");
  if (window.QRCode) new QRCode(box, {text: data.token || "", width: 190, height: 190});
  else box.textContent = data.token || "";
}

async function renderLocations() {
  appLayout(t("locations"), `<div class="panel"><button class="primary-btn" id="refresh">${t("save")}</button></div><div id="locationRows" class="stack"></div>`);
  document.getElementById("refresh").onclick = loadLocations;
  await loadLocations();
}

async function loadLocations() {
  const data = await api(`/locations?actorEmail=${encodeURIComponent(state.user.email)}`);
  const rows = data.items || [];
  document.getElementById("locationRows").innerHTML = rows.length ? rows.map((item) => `<div class="list-item"><div class="main"><strong>${escapeHtml(item.email)}</strong><small><a href="${escapeHtml(item.url)}" target="_blank" rel="noreferrer">${escapeHtml(item.url)}</a><br>${escapeHtml(item.created_at || "")}</small></div></div>`).join("") : `<p>${t("empty")}</p>`;
}

async function renderCompanySite(message = "") {
  const data = await api(`/company-location?actorEmail=${encodeURIComponent(state.user.email)}`);
  const loc = data.location || {};
  appLayout(t("companySite"), `<form class="panel light-form" id="siteForm">${field("latitude", t("latitude"), "number", loc.latitude || "")}${field("longitude", t("longitude"), "number", loc.longitude || "")}${field("radiusMeters", t("radius"), "number", loc.radiusMeters || 150)}<div class="actions"><button class="secondary-btn" type="button" id="usePos">${t("usePosition")}</button><button class="primary-btn" type="submit">${t("save")}</button></div>${message ? `<div class="message ${message.startsWith("!") ? "error" : "ok"}">${escapeHtml(message.replace(/^!/, ""))}</div>` : ""}</form>`);
  document.getElementById("usePos").onclick = useCurrentPositionInForm;
  document.getElementById("siteForm").onsubmit = saveCompanySite;
}

function useCurrentPositionInForm() {
  navigator.geolocation?.getCurrentPosition((pos) => {
    document.getElementById("latitude").value = pos.coords.latitude.toFixed(7);
    document.getElementById("longitude").value = pos.coords.longitude.toFixed(7);
  });
}

async function saveCompanySite(event) {
  event.preventDefault();
  const data = await api("/company-location", {method: "PUT", body: JSON.stringify({...formData(event.currentTarget), actorEmail: state.user.email})});
  renderCompanySite(data.ok ? t("save") : "!" + reasonText(data.reason));
}

async function renderReports() {
  appLayout(t("reports"), `<div class="toolbar light-form">${field("month", t("month"), "month", monthToken(new Date()))}<button class="primary-btn" id="reload">${t("save")}</button></div><div id="reportRows" class="stack"></div>`);
  document.getElementById("reload").onclick = loadReports;
  document.getElementById("month").onchange = loadReports;
  await loadReports();
}

async function loadReports() {
  const month = document.getElementById("month").value;
  const data = await api(`/attendance/report?month=${encodeURIComponent(month)}&actorEmail=${encodeURIComponent(state.user.email)}`);
  const rows = data.items || [];
  document.getElementById("reportRows").innerHTML = rows.length ? rows.map((item) => `<div class="list-item"><div class="main"><strong>${escapeHtml(item.name)}</strong><small>${t("present")}: ${item.present} · ${t("absent")}: ${item.absent}</small></div></div>`).join("") : `<p>${t("empty")}</p>`;
}

async function renderStats() {
  const data = await api(`/attendance/report?month=${monthToken(new Date())}&actorEmail=${encodeURIComponent(state.user.email)}`);
  const rows = data.items || [];
  const present = rows.reduce((sum, item) => sum + Number(item.present || 0), 0);
  const absent = rows.reduce((sum, item) => sum + Number(item.absent || 0), 0);
  const rate = present + absent ? Math.round((present / (present + absent)) * 100) : 0;
  appLayout(t("stats"), `<div class="stats-grid"><div class="stat-tile"><b>${present}</b><span>${t("present")}</span></div><div class="stat-tile"><b>${absent}</b><span>${t("absent")}</span></div><div class="stat-tile"><b>${rate}%</b><span>${t("attendance")}</span></div></div>`);
}

async function renderDeveloper() {
  appLayout(t("developer"), `
    <div class="panel">
      <div class="actions">
        <button class="primary-btn" id="addCompany">${t("add")} ${t("companies")}</button>
        <button class="secondary-btn" id="refreshDeveloper">${t("save")}</button>
      </div>
    </div>
    <div class="panel"><h2>${t("companies")}</h2><div id="companyRows" class="stack"></div></div>
    <div class="panel"><h2>${t("users")}</h2><div id="developerUsers" class="stack"></div></div>`, true);
  document.getElementById("addCompany").onclick = addCompanyPrompt;
  document.getElementById("refreshDeveloper").onclick = loadDeveloperData;
  await loadDeveloperData();
}

async function loadDeveloperData() {
  await loadCompanies();
  await loadDeveloperUsers();
}

async function loadCompanies() {
  const data = await api(`/developer/companies?actorEmail=${encodeURIComponent(state.user.email)}`);
  const rows = data.companies || [];
  document.getElementById("companyRows").innerHTML = rows.length ? rows.map((company) => `<div class="list-item"><div class="main"><strong>${escapeHtml(company.name)}</strong><small>${company.userCount || 0} comptes</small></div><span class="badge ${company.status === "frozen" ? "bad" : "ok"}">${company.status === "frozen" ? t("frozen") : t("active")}</span><button class="secondary-btn" data-company-toggle="${company.id}" data-status="${company.status}">${company.status === "frozen" ? t("active") : t("frozen")}</button></div>`).join("") : `<p>${t("empty")}</p>`;
}

async function loadDeveloperUsers() {
  const companiesData = await api(`/developer/companies?actorEmail=${encodeURIComponent(state.user.email)}`);
  const companies = companiesData.companies || [];
  const usersData = await api(`/admin/users?status=all&actorEmail=${encodeURIComponent(state.user.email)}`);
  const users = usersData.users || [];
  const options = companies.map((company) => `<option value="${company.id}">${escapeHtml(company.name)}</option>`).join("");
  document.getElementById("developerUsers").innerHTML = users.length ? users.map((user) => `
    <div class="list-item">
      <div class="main">
        <strong>${escapeHtml(user.fullName)}</strong>
        <small>${escapeHtml(user.email)} · ${escapeHtml(user.role)} · ${escapeHtml(user.companyName || "")}</small>
      </div>
      <select data-company-user="${user.id}" aria-label="${t("companies")}">
        <option value="">${t("companies")}</option>
        ${companies.map((company) => `<option value="${company.id}" ${String(user.companyId || "") === String(company.id) ? "selected" : ""}>${escapeHtml(company.name)}</option>`).join("") || options}
      </select>
      <button class="primary-btn" data-assign-company="${user.id}">${t("save")}</button>
    </div>`).join("") : `<p>${t("empty")}</p>`;
}

async function addCompanyPrompt() {
  const name = prompt(t("companies"));
  const adminName = prompt(t("fullName"));
  const adminEmail = prompt(t("email"));
  const adminPassword = prompt(t("password")) || "Temp1234";
  if (!name || !adminName || !adminEmail) return;
  await api("/developer/companies", {method: "POST", body: JSON.stringify({actorEmail: state.user.email, name, adminName, adminEmail, adminPassword})});
  loadCompanies();
}

function formData(form) {
  return Object.fromEntries(new FormData(form).entries());
}

function monthToken(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function reasonText(reason) {
  return {
    pending: "Compte en attente",
    rejected: "Compte refuse",
    company_frozen: "Compte entreprise suspendu",
    invalid: "Identifiants invalides",
    not_found: "Utilisateur introuvable",
    email_exists: "Email existe deja",
    required: "Champs requis",
    otp_invalid: "Code invalide",
    expired: "Code expire",
    forbidden: "Acces refuse",
  }[reason] || reason || "Erreur";
}

document.addEventListener("click", async (event) => {
  const target = event.target.closest("button");
  if (!target) return;
  if (target.dataset.lang) {
    state.lang = target.dataset.lang;
    localStorage.setItem("codeva_lang", state.lang);
    state.user ? routeForRole() : renderLogin();
  }
  if (target.dataset.view === "login") renderLogin();
  if (target.dataset.view === "signup") renderSignup();
  if (target.dataset.view === "forgot") renderForgot();
  if (target.dataset.view === "change") renderChange();
  if (target.dataset.action === "logout") { setUser(null); renderLogin(); }
  if (target.dataset.action === "home") routeForRole();
  if (target.dataset.admin === "requests") renderRequests();
  if (target.dataset.admin === "attendance") renderAttendance();
  if (target.dataset.admin === "qr") renderQr();
  if (target.dataset.admin === "locations") renderLocations();
  if (target.dataset.admin === "site") renderCompanySite();
  if (target.dataset.admin === "reports") renderReports();
  if (target.dataset.admin === "stats") renderStats();
  if (target.dataset.approve) {
    await api(`/admin/users/${target.dataset.approve}/approve?actorEmail=${encodeURIComponent(state.user.email)}`, {method: "POST"});
    loadUsers();
  }
  if (target.dataset.reject) {
    await api(`/admin/users/${target.dataset.reject}/reject?actorEmail=${encodeURIComponent(state.user.email)}`, {method: "POST"});
    loadUsers();
  }
  if (target.dataset.companyToggle) {
    const action = target.dataset.status === "frozen" ? "activate" : "freeze";
    await api(`/developer/companies/${target.dataset.companyToggle}/${action}?actorEmail=${encodeURIComponent(state.user.email)}`, {method: "POST"});
    loadCompanies();
  }
  if (target.dataset.assignCompany) {
    const selector = document.querySelector(`[data-company-user="${target.dataset.assignCompany}"]`);
    const companyId = selector?.value;
    if (!companyId) return;
    await api(`/developer/users/${target.dataset.assignCompany}/company`, {
      method: "POST",
      body: JSON.stringify({actorEmail: state.user.email, companyId}),
    });
    loadDeveloperData();
  }
});

state.user ? routeForRole() : renderLogin();
