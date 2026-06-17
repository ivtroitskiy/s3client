## Что изменено

- 

## Проверка

- [ ] `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-cf.ps1`
- [ ] Интеграционный сценарий `tests/minio-smoke.bsl`, если изменение затрагивает S3-запросы

## Безопасность

- [ ] В PR нет реальных ключей доступа, production bucket или internal endpoint
- [ ] Примеры используют только локальные тестовые значения
