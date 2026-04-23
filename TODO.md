# TODO - Fix envoi media localhost

- [x] Analyser la config API Flutter et le flux d’upload media présigné.
- [x] Ajouter une adaptation d’URL présignée en dev local Android émulateur (`localhost/127.0.0.1` -> `10.0.2.2`).
- [x] Corriger le PUT présigné pour préserver strictement host/port/query signés.
- [x] Renforcer les logs de diagnostic (URL effective avec port + query length).
- [ ] Vérifier statiquement la cohérence du code modifié.
- [ ] Finaliser et résumer le correctif appliqué.
