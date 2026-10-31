import { useCallback, useEffect, useMemo, useState } from "react";

const API = "http://localhost:8080/api/auth/admins";
const labels = {
    fr: { title: "Gestion des administrateurs", subtitle: "Ajoutez et gérez les comptes qui ont accès au tableau de bord.", add: "Ajouter un administrateur", username: "Nom d'utilisateur", email: "Adresse e-mail", password: "Mot de passe", confirmPassword: "Confirmer le mot de passe", create: "Créer le compte", cancel: "Annuler", active: "Actif", inactive: "Désactivé", edit: "Modifier", changePassword: "Changer le mot de passe", disable: "Désactiver", enable: "Réactiver", remove: "Supprimer", noAdmins: "Aucun administrateur trouvé.", search: "Rechercher par nom ou e-mail...", loading: "Chargement…", save: "Enregistrer", newPassword: "Nouveau mot de passe (8 caractères minimum)", passwordMismatch: "Les mots de passe ne correspondent pas.", created: "Administrateur ajouté.", updated: "Compte administrateur modifié.", passwordUpdated: "Mot de passe modifié.", activated: "Compte réactivé.", deactivated: "Compte désactivé.", deleted: "Administrateur supprimé.", confirmDelete: "Supprimer définitivement cet administrateur ?", selfError: "Vous ne pouvez pas désactiver ou supprimer votre propre compte.", safeDelete: "La suppression est possible uniquement si le compte ne possède aucun événement, inscription, projet, article ou message.", loadError: "Impossible de charger les administrateurs.", status: "Statut", actions: "Actions", count: n => `${n} administrateur(s)` },
    en: { title: "Administrator management", subtitle: "Add and manage accounts that can access the dashboard.", add: "Add administrator", username: "Username", email: "Email address", password: "Initial password (at least 8 characters)", confirmPassword: "Confirm password", create: "Create account", cancel: "Cancel", active: "Active", inactive: "Disabled", edit: "Edit", changePassword: "Change password", disable: "Disable", enable: "Reactivate", remove: "Delete", noAdmins: "No administrators found.", search: "Search by name or email...", loading: "Loading…", save: "Save", newPassword: "New password (at least 8 characters)", passwordMismatch: "Passwords do not match.", created: "Administrator added.", updated: "Administrator account updated.", passwordUpdated: "Password updated.", activated: "Account reactivated.", deactivated: "Account disabled.", deleted: "Administrator deleted.", confirmDelete: "Permanently delete this administrator?", selfError: "You cannot disable or delete your own account.", safeDelete: "Deletion is allowed only when the account has no events, registrations, projects, articles, or messages.", loadError: "Could not load administrators.", status: "Status", actions: "Actions", count: n => `${n} administrator(s)` },
    nl: { title: "Beheerders beheren", subtitle: "Voeg accounts toe en beheer de toegang tot het dashboard.", add: "Beheerder toevoegen", username: "Gebruikersnaam", email: "E-mailadres", password: "Startwachtwoord (minstens 8 tekens)", confirmPassword: "Wachtwoord bevestigen", create: "Account aanmaken", cancel: "Annuleren", active: "Actief", inactive: "Uitgeschakeld", edit: "Bewerken", changePassword: "Wachtwoord wijzigen", disable: "Uitschakelen", enable: "Opnieuw activeren", remove: "Verwijderen", noAdmins: "Geen beheerders gevonden.", search: "Zoeken op naam of e-mail...", loading: "Laden…", save: "Opslaan", newPassword: "Nieuw wachtwoord (minstens 8 tekens)", passwordMismatch: "De wachtwoorden komen niet overeen.", created: "Beheerder toegevoegd.", updated: "Beheerdersaccount bijgewerkt.", passwordUpdated: "Wachtwoord bijgewerkt.", activated: "Account opnieuw geactiveerd.", deactivated: "Account uitgeschakeld.", deleted: "Beheerder verwijderd.", confirmDelete: "Deze beheerder definitief verwijderen?", selfError: "Je kunt je eigen account niet uitschakelen of verwijderen.", safeDelete: "Verwijderen kan alleen als het account geen evenementen, inschrijvingen, projecten, artikelen of berichten heeft.", loadError: "Beheerders konden niet worden geladen.", status: "Status", actions: "Acties", count: n => `${n} beheerder(s)` }
};

function getError(data, fallback) {
    return data?.message || data?.error || fallback;
}

export default function AdminManagement({ lang = "fr" }) {
    const t = labels[lang] || labels.fr;
    const [admins, setAdmins] = useState([]);
    const [currentAdminId, setCurrentAdminId] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [notice, setNotice] = useState("");
    const [search, setSearch] = useState("");
    const [createForm, setCreateForm] = useState({ username: "", email: "", password: "", confirmPassword: "" });
    const [editTarget, setEditTarget] = useState(null);
    const [passwordTarget, setPasswordTarget] = useState(null);
    const [newPassword, setNewPassword] = useState("");

    const headers = () => ({ Authorization: `Bearer ${localStorage.getItem("token") || ""}` });

    const loadAdmins = useCallback(async () => {
        setLoading(true);
        setError("");
        try {
            const [listResponse, meResponse] = await Promise.all([
                fetch(API, { headers: headers() }),
                fetch("http://localhost:8080/api/auth/me", { headers: headers() })
            ]);
            const listData = await listResponse.json().catch(() => []);
            const meData = await meResponse.json().catch(() => ({}));
            if (!listResponse.ok) throw new Error(getError(listData, t.loadError));
            if (!meResponse.ok) throw new Error(getError(meData, t.loadError));
            setAdmins(Array.isArray(listData) ? listData : []);
            setCurrentAdminId(meData.id ?? null);
        } catch (err) {
            setError(err.message || t.loadError);
        } finally {
            setLoading(false);
        }
    }, [t.loadError]);

    useEffect(() => { loadAdmins(); }, [loadAdmins]);

    const filteredAdmins = useMemo(() => {
        const query = search.trim().toLowerCase();
        if (!query) return admins;
        return admins.filter(admin => `${admin.username || ""} ${admin.email || ""}`.toLowerCase().includes(query));
    }, [admins, search]);

    async function request(url, method, body) {
        const response = await fetch(url, {
            method,
            headers: { ...headers(), ...(body ? { "Content-Type": "application/json" } : {}) },
            ...(body ? { body: JSON.stringify(body) } : {})
        });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(getError(data, t.loadError));
        return data;
    }

    async function createAdmin(event) {
        event.preventDefault();
        setError("");
        setNotice("");
        if (createForm.password !== createForm.confirmPassword) return setError(t.passwordMismatch);
        try {
            const data = await request(API, "POST", {
                username: createForm.username,
                email: createForm.email,
                password: createForm.password
            });
            setCreateForm({ username: "", email: "", password: "", confirmPassword: "" });
            setNotice(data.message || t.created);
            await loadAdmins();
        } catch (err) { setError(err.message); }
    }

    async function saveProfile(event) {
        event.preventDefault();
        setError("");
        try {
            const data = await request(`${API}/${editTarget.id}/profile`, "PUT", {
                username: editTarget.username,
                email: editTarget.email
            });
            if (data.token) localStorage.setItem("token", data.token);
            setEditTarget(null);
            setNotice(t.updated);
            await loadAdmins();
        } catch (err) { setError(err.message); }
    }

    async function savePassword(event) {
        event.preventDefault();
        setError("");
        if (!newPassword || newPassword.length < 8) return setError(t.newPassword);
        try {
            await request(`${API}/${passwordTarget.id}/password`, "PUT", { newPassword });
            setPasswordTarget(null);
            setNewPassword("");
            setNotice(t.passwordUpdated);
        } catch (err) { setError(err.message); }
    }

    async function toggleAdmin(admin) {
        setError("");
        setNotice("");
        try {
            const data = await request(`${API}/${admin.id}/toggle-active`, "PUT");
            setNotice(data.message || (admin.active ? t.deactivated : t.activated));
            await loadAdmins();
        } catch (err) { setError(err.message); }
    }

    async function deleteAdmin(admin) {
        if (!window.confirm(t.confirmDelete)) return;
        setError("");
        setNotice("");
        try {
            const data = await request(`${API}/${admin.id}`, "DELETE");
            setNotice(data.message || t.deleted);
            await loadAdmins();
        } catch (err) { setError(err.message); }
    }

    const inputStyle = { width: "100%", boxSizing: "border-box", padding: "10px 12px", border: "1px solid #d8ded9", borderRadius: 8, fontSize: 14, marginTop: 5 };
    const button = { border: 0, borderRadius: 7, padding: "9px 13px", cursor: "pointer", fontWeight: 600, fontSize: 13 };
    const modalStyle = { position: "fixed", inset: 0, background: "rgba(0,0,0,.48)", zIndex: 2000, display: "flex", alignItems: "center", justifyContent: "center", padding: 20 };

    return <div style={{ background: "#fff", border: "1px solid #e4e9e5", borderRadius: 12, padding: 24, marginBottom: 20 }}>
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 16, flexWrap: "wrap" }}>
            <div><h2 style={{ margin: "0 0 8px", color: "#1b1b1b", fontSize: 20 }}>{t.title}</h2><p style={{ color: "#6b7280", margin: 0, fontSize: 13 }}>{t.subtitle}</p></div>
            <span style={{ background: "#e8f5e9", color: "#2d6a4f", borderRadius: 20, padding: "7px 12px", fontSize: 12, fontWeight: 700 }}>{t.count(admins.length)}</span>
        </div>
        <p style={{ color: "#777", fontSize: 12, margin: "12px 0 20px" }}>{t.safeDelete}</p>
        {notice && <div role="status" style={{ background: "#e8f5e9", color: "#25633c", padding: 11, borderRadius: 7, marginBottom: 14 }}>{notice}</div>}
        {error && <div role="alert" style={{ background: "#ffebee", color: "#b42318", padding: 11, borderRadius: 7, marginBottom: 14 }}>{error}</div>}

        <form onSubmit={createAdmin} style={{ background: "#f8faf8", border: "1px solid #e7ece8", borderRadius: 10, padding: 18, display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(190px,1fr))", gap: 12, marginBottom: 22 }}>
            <div style={{ gridColumn: "1/-1", fontWeight: 700, color: "#2d6a4f" }}>{t.add}</div>
            <label>{t.username}<input style={inputStyle} value={createForm.username} onChange={e => setCreateForm({ ...createForm, username: e.target.value })} required /></label>
            <label>{t.email}<input type="email" style={inputStyle} value={createForm.email} onChange={e => setCreateForm({ ...createForm, email: e.target.value })} required /></label>
            <label>{t.password}<input type="password" minLength={8} style={inputStyle} value={createForm.password} onChange={e => setCreateForm({ ...createForm, password: e.target.value })} required /></label>
            <label>{t.confirmPassword}<input type="password" minLength={8} style={inputStyle} value={createForm.confirmPassword} onChange={e => setCreateForm({ ...createForm, confirmPassword: e.target.value })} required /></label>
            <div style={{ gridColumn: "1/-1" }}><button type="submit" style={{ ...button, background: "#2d6a4f", color: "white" }}>{t.create}</button></div>
        </form>

        <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap", alignItems: "center", marginBottom: 12 }}>
            <input aria-label={t.search} placeholder={t.search} value={search} onChange={e => setSearch(e.target.value)} style={{ ...inputStyle, maxWidth: 360, marginTop: 0 }} />
            <button onClick={loadAdmins} title={t.title} aria-label={t.title} style={{ ...button, background: "#eef3ef", color: "#2d6a4f" }}>↻</button>
        </div>
        {loading ? <p style={{ textAlign: "center", color: "#777", padding: 24 }}>{t.loading}</p> : filteredAdmins.length === 0 ? <p style={{ textAlign: "center", color: "#888", padding: 24 }}>{t.noAdmins}</p> : filteredAdmins.map(admin => {
            const isSelf = currentAdminId != null && Number(currentAdminId) === Number(admin.id);
            return <article key={admin.id} style={{ border: "1px solid #e5e9e6", borderRadius: 10, padding: 16, marginTop: 10, display: "flex", justifyContent: "space-between", alignItems: "center", gap: 16, flexWrap: "wrap", opacity: admin.active ? 1 : .68 }}>
                <div style={{ display: "flex", gap: 12, alignItems: "center", minWidth: 220 }}>
                    <div style={{ width: 42, height: 42, borderRadius: "50%", display: "grid", placeItems: "center", background: "#e8f5e9", color: "#2d6a4f", fontWeight: 800 }}>{(admin.username || "A").charAt(0).toUpperCase()}</div>
                    <div><div style={{ fontWeight: 700, color: "#222" }}>{admin.username} {isSelf && <small style={{ color: "#777" }}>(vous)</small>}</div><div style={{ color: "#2d6a4f", fontSize: 13 }}>{admin.email || "—"}</div><span style={{ display: "inline-block", marginTop: 5, borderRadius: 20, padding: "3px 9px", background: admin.active ? "#e8f5e9" : "#ffebee", color: admin.active ? "#25633c" : "#b42318", fontSize: 11, fontWeight: 700 }}>{admin.active ? t.active : t.inactive}</span></div>
                </div>
                <div style={{ display: "flex", gap: 7, flexWrap: "wrap" }}>
                    <button onClick={() => { setError(""); setEditTarget({ ...admin }); }} style={{ ...button, background: "#e3f2fd", color: "#1565c0" }}>{t.edit}</button>
                    <button onClick={() => { setError(""); setPasswordTarget(admin); setNewPassword(""); }} style={{ ...button, background: "#f3e5f5", color: "#7b1fa2" }}>{t.changePassword}</button>
                    {!isSelf && <><button onClick={() => toggleAdmin(admin)} style={{ ...button, background: admin.active ? "#fff3e0" : "#e8f5e9", color: admin.active ? "#9a5a00" : "#25633c" }}>{admin.active ? t.disable : t.enable}</button><button onClick={() => deleteAdmin(admin)} style={{ ...button, background: "#ffebee", color: "#b42318" }}>{t.remove}</button></>}
                </div>
            </article>;
        })}

        {editTarget && <div style={modalStyle}><form onSubmit={saveProfile} style={{ background: "white", borderRadius: 12, padding: 24, width: "min(480px,100%)", boxShadow: "0 10px 35px #0003" }}><h3 style={{ marginTop: 0 }}>{t.edit} : {editTarget.username}</h3><label>{t.username}<input style={inputStyle} value={editTarget.username || ""} onChange={e => setEditTarget({ ...editTarget, username: e.target.value })} required /></label><label style={{ display: "block", marginTop: 12 }}>{t.email}<input type="email" style={inputStyle} value={editTarget.email || ""} onChange={e => setEditTarget({ ...editTarget, email: e.target.value })} required /></label><div style={{ display: "flex", gap: 10, marginTop: 20 }}><button style={{ ...button, background: "#2d6a4f", color: "white" }}>{t.save}</button><button type="button" onClick={() => setEditTarget(null)} style={{ ...button, background: "#f1f3f1" }}>{t.cancel}</button></div></form></div>}
        {passwordTarget && <div style={modalStyle}><form onSubmit={savePassword} style={{ background: "white", borderRadius: 12, padding: 24, width: "min(480px,100%)", boxShadow: "0 10px 35px #0003" }}><h3 style={{ marginTop: 0 }}>{t.changePassword} : {passwordTarget.username}</h3><label>{t.newPassword}<input type="password" minLength={8} style={inputStyle} value={newPassword} onChange={e => setNewPassword(e.target.value)} required /></label><div style={{ display: "flex", gap: 10, marginTop: 20 }}><button style={{ ...button, background: "#2d6a4f", color: "white" }}>{t.save}</button><button type="button" onClick={() => setPasswordTarget(null)} style={{ ...button, background: "#f1f3f1" }}>{t.cancel}</button></div></form></div>}
    </div>;
}
