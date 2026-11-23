# Monster Kundenportal

Produktcode-Basis für **monster-ds.de**, getrennt vom Softwarevertrieb auf monsterdigitalsolutions.de.

## Enthalten
- Responsive Login-Oberfläche mit Firmenkürzel, persönlicher E-Mail und Passwort
- Supabase-Authentifizierung und Abgleich der Firmenzuordnung
- Rollenspezifische Navigation für Inhaber, Verwaltung und Handwerker
- Datenbankmigration für Firmen, Profile, Mitarbeiter, Kunden, Fahrzeuge, Schichten, Aufträge, AW-Tätigkeiten, Lager, Berichte und Fotos
- Mandantentrennung per PostgreSQL Row Level Security (RLS), Lesezugriffe eingeschränkt
- Echtes Dashboard mit Abfragen gegen die Datenbank; keine erfundenen Datensätze

## Noch nicht fertig / nicht produktiv freigeben
- Serverseitige Einrichtung von Firmen und Benutzern, sichere Einladungen und Rechteänderungen
- Vollständige CRUD-Formulare und feinere Berechtigungsregeln je Modul
- Offline-PWA mit verschlüsselter lokaler Speicherung, Sync-Queue, Konfliktauflösung und Wiederholungslogik
- Kundenunterschrift, Foto-Upload, PDF, Druck, AW-Berechnung und verbindliche Freigaben
- Audit-Logs, Datenschutzkonzept, Backups und Wiederherstellungstests
- TLS/HTTPS, Reverse Proxy, DNS, Monitoring, Rate Limits und SMTP

**Die Oberfläche ist keine Demo mit falschen Logins:** Ohne echte Backend-Konfiguration ist die Anmeldung gesperrt. Datenbankänderungen sind vorerst ebenfalls gesperrt.

## Lokaler Start

```bash
npm install
cp .env.example .env
# VITE_SUPABASE_URL und VITE_SUPABASE_ANON_KEY eintragen
npm run dev
```

## Server / Datenbank
1. Bestehende MonsterLizenz-Installation vor Änderungen sichern.
2. Eigene Datenbank / eigenes Supabase-Projekt für das Portal bereitstellen. **Nicht** blind in die Lizenzdatenbank migrieren.
3. SQL-Migration `supabase/migrations/001_portal.sql` auf dem Portal-Datenbankprojekt ausführen und RLS mit mehreren Firmenkonten testen.
4. Ersten Firmeninhaber nur über vertrauenswürdigen Admin-Prozess anlegen. Niemals `service_role`-Schlüssel ins Frontend schreiben.
5. Produktionsbuild: `npm run build`; Verzeichnis `dist/` über HTTPS ausliefern, SPA-Routing konfigurieren.
6. Auth-URLs, CORS, CSP und Domain `monster-ds.de` konfigurieren.

**Sicherheit:** Eine unbekannte URL ist kein Zugriffsschutz. Vor dem Livegang Sicherheitsprüfung und Tests mit mehreren Mandanten durchführen.
