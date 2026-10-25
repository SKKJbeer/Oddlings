#!/usr/bin/env python3
"""App Store Connect über die Schnittstelle: Bundle-ID, Signatur, TestFlight.

Übernommen aus CardBeacon (Repo NewIdea, ios/scripts/signatur.py und
testflight.py) und auf Oddlings zugeschnitten.

  apple.py vorbereiten                Bundle-ID registrieren, App-Eintrag prüfen
  apple.py signatur-anlegen <ordner>  Verteilzertifikat + App-Store-Profil erzeugen
  apple.py signatur-aufraeumen <ordner>  beides bei Apple wieder löschen
  apple.py testflight                 auf den neuesten Bau warten (VALID), interne
                                      Gruppe „Team“ mit allen Bauten, Team einladen

Umgebung: KEY_ID, ISSUER, KEY_P8 (Schlüssel mit Rolle Admin).

Warum die Signatur jedes Mal neu entsteht: Der private Schlüssel wird auf dem
Läufer erzeugt und verlässt ihn nie, es gibt also kein weiteres Geheimnis zu
verwalten. Apple begrenzt die Zahl der Verteilzertifikate, deshalb wird nach
dem Hochladen gelöscht; hochgeladene Bauten bleiben davon unberührt.
"""
import base64, json, os, sys, time, urllib.error, urllib.request, secrets as zufall

import jwt

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE = "de.skkjbeer.oddlings"
NAME = "Oddlings"


class AppleFehler(Exception):
    def __init__(self, code, text):
        super().__init__(f"HTTP {code}: {text[:700]}")
        self.code = code


def token() -> str:
    t = int(time.time())
    return jwt.encode({"iss": os.environ["ISSUER"], "iat": t, "exp": t + 1100, "aud": "appstoreconnect-v1"},
                      os.environ["KEY_P8"], algorithm="ES256", headers={"kid": os.environ["KEY_ID"], "typ": "JWT"})


def api(methode, pfad, daten=None):
    req = urllib.request.Request(API + pfad, method=methode,
                                 data=json.dumps(daten).encode() if daten is not None else None,
                                 headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            text = r.read()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        raise AppleFehler(e.code, e.read().decode())


def bundle_id():
    # Apples filter[identifier] filtert als Präfix: de.x.app fände auch
    # de.x.app.widget. Deshalb genau vergleichen (Baukasten, Abschnitt 4).
    for b in api("GET", f"/bundleIds?filter%5Bidentifier%5D={BUNDLE}&limit=50")["data"]:
        if b["attributes"]["identifier"] == BUNDLE:
            return b["id"]
    return None


def app_id():
    for a in api("GET", f"/apps?filter%5BbundleId%5D={BUNDLE}")["data"]:
        if a["attributes"]["bundleId"] == BUNDLE:
            return a["id"]
    return None


def vorbereiten():
    bid = bundle_id()
    if bid:
        print(f"Bundle-ID {BUNDLE} vorhanden.")
    else:
        api("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": BUNDLE, "name": NAME, "platform": "IOS"}}})
        print(f"Bundle-ID {BUNDLE} registriert.")
    if not app_id():
        # Apple lehnt das Anlegen eines App-Eintrags über die Schnittstelle ab
        # (403, in CardBeacon am 07.10.2026 belegt). Klare Meldung statt Versuch.
        print(f"::error::Der App-Eintrag fehlt. Einmalig von Hand anlegen: App Store Connect → Apps → + → "
              f"Neue App, Plattform iOS, Bundle-ID {BUNDLE}. Danach diesen Lauf neu starten.")
        sys.exit(1)
    print("App-Eintrag vorhanden.")


def signatur_anlegen(ordner):
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives.serialization import pkcs12
    from cryptography.x509.oid import NameOID

    os.makedirs(ordner, exist_ok=True)
    bid = bundle_id()
    if not bid:
        sys.exit(f"Bundle-ID {BUNDLE} fehlt – erst 'vorbereiten' laufen lassen.")

    schluessel = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (x509.CertificateSigningRequestBuilder()
           .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Oddlings CI")]))
           .sign(schluessel, hashes.SHA256()))
    zert = api("POST", "/certificates", {"data": {"type": "certificates", "attributes": {
        "certificateType": "DISTRIBUTION",
        "csrContent": csr.public_bytes(serialization.Encoding.PEM).decode()}}})["data"]
    # Die Kennung sofort sichern: Scheitert ein späterer Schritt, findet das
    # Aufräumen das Zertifikat trotzdem, statt es bei Apple liegen zu lassen.
    ids = {"zertifikat": zert["id"]}
    json.dump(ids, open(os.path.join(ordner, "ids.json"), "w"))
    cert = x509.load_der_x509_certificate(base64.b64decode(zert["attributes"]["certificateContent"]))

    passwort = zufall.token_urlsafe(18)
    # Klassisches PKCS12 (SHA1/3DES): `security import` auf macOS liest die
    # moderne AES-Variante nicht und meldet irreführend "MAC verification failed".
    verschluesselung = (serialization.PrivateFormat.PKCS12.encryption_builder()
                        .kdf_rounds(50000)
                        .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC)
                        .hmac_hash(hashes.SHA1())
                        .build(passwort.encode()))
    p12 = pkcs12.serialize_key_and_certificates(b"oddlings-ci", schluessel, cert, None, verschluesselung)
    open(os.path.join(ordner, "signatur.p12"), "wb").write(p12)

    name = f"Oddlings CI {int(time.time())}"
    profil = api("POST", "/profiles", {"data": {"type": "profiles",
        "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
        "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bid}},
                          "certificates": {"data": [{"type": "certificates", "id": zert["id"]}]}}}})["data"]
    open(os.path.join(ordner, "profil.mobileprovision"), "wb").write(
        base64.b64decode(profil["attributes"]["profileContent"]))
    ids.update({"profil": profil["id"], "profilName": name, "profilUuid": profil["attributes"]["uuid"],
                "passwort": passwort})
    json.dump(ids, open(os.path.join(ordner, "ids.json"), "w"))
    print(f"Zertifikat {zert['id']} und Profil '{name}' angelegt.")


def signatur_aufraeumen(ordner):
    pfad = os.path.join(ordner, "ids.json")
    if not os.path.exists(pfad):
        print("Nichts aufzuräumen.")
        return
    ids = json.load(open(pfad))
    for art, feld in (("profiles", "profil"), ("certificates", "zertifikat")):
        if feld not in ids:
            continue
        try:
            api("DELETE", f"/{art}/{ids[feld]}")
            print(f"{art} {ids[feld]} gelöscht.")
        except AppleFehler as e:
            print(f"::warning::{art} {ids[feld]} nicht gelöscht: {e}")


def neuester_bau(app, version, warten_min=40):
    ende = time.time() + warten_min * 60
    while True:
        for b in api("GET", f"/builds?filter%5Bapp%5D={app}&filter%5Bversion%5D={version}&limit=1")["data"]:
            zustand = b["attributes"]["processingState"]
            print(f"Bau {version}: {zustand}")
            if zustand == "VALID":
                return b
            if zustand in ("FAILED", "INVALID"):
                sys.exit(f"Apple hat Bau {version} abgelehnt ({zustand}).")
        if time.time() > ende:
            sys.exit(f"Bau {version} ist nach {warten_min} Minuten noch nicht verarbeitet.")
        time.sleep(30)


def gruppe(app, name, attribute):
    for g in api("GET", f"/apps/{app}/betaGroups?limit=50")["data"]:
        if g["attributes"]["name"] == name:
            return g
    return api("POST", "/betaGroups", {"data": {"type": "betaGroups", "attributes": {"name": name, **attribute},
               "relationships": {"app": {"data": {"type": "apps", "id": app}}}}})["data"]


def testflight():
    version = os.environ["BUILD_NUMBER"]
    app = app_id()
    neuester_bau(app, version)
    # Interne Gruppe mit Zugriff auf alle Bauten: Jeder neue Bau erscheint dann
    # ohne weiteren Schritt und ohne Beta-Prüfung in TestFlight.
    intern = gruppe(app, "Team", {"isInternalGroup": True, "hasAccessToAllBuilds": True})
    for u in api("GET", "/users?limit=50")["data"]:
        a = u["attributes"]
        mail = a.get("username") or a.get("email")
        if not mail:
            continue
        try:
            api("POST", "/betaTesters", {"data": {"type": "betaTesters",
                "attributes": {"email": mail, "firstName": a.get("firstName") or "", "lastName": a.get("lastName") or ""},
                "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": intern["id"]}]}}}})
            print("Teammitglied in die Gruppe „Team“ eingeladen.")
        except AppleFehler as e:
            print("Teammitglied bereits in der Gruppe." if e.code == 409 else f"::warning::Einladung: {e}")
    print(f"Bau {version}: VALID, in der Gruppe „Team“ verfügbar.")


if __name__ == "__main__":
    befehl = sys.argv[1]
    if befehl == "vorbereiten":
        vorbereiten()
    elif befehl == "signatur-anlegen":
        signatur_anlegen(sys.argv[2])
    elif befehl == "signatur-aufraeumen":
        signatur_aufraeumen(sys.argv[2])
    elif befehl == "testflight":
        testflight()
    else:
        sys.exit(__doc__)
