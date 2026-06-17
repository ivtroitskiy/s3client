# Локальный MinIO для S3Клиент

Инструкция рассчитана на Docker Desktop под Windows.

Данные доступа ниже предназначены только для локальной разработки. Не используйте эти значения в production и не коммитьте реальные ключи доступа в репозиторий.

## Запуск контейнера

Самый короткий вариант из корня репозитория:

```powershell
docker compose -f docker-compose.minio.yml up -d
```

Альтернативный ручной запуск:

Создайте каталог для данных:

```powershell
mkdir C:\minio-data
```

Запустите MinIO:

```powershell
docker run -d --name minio `
  -p 9000:9000 -p 9001:9001 `
  -e MINIO_ROOT_USER=minioadmin `
  -e MINIO_ROOT_PASSWORD=minioadmin123 `
  -v C:\minio-data:/data `
  quay.io/minio/minio server /data --console-address ":9001"
```

Консоль управления будет доступна по адресу:

```text
http://localhost:9001
```

Данные входа:

```text
Пользователь: minioadmin
Пароль: minioadmin123
```

## Bucket

Для разработки используется bucket:

```text
s3client-dev
```

Если bucket еще не создан, создайте его в консоли MinIO: `Buckets` -> `Create Bucket`.

## Параметры подключения для 1С

```bsl
ПараметрыS3 = S3Клиент.ПараметрыПодключения(
	"http://localhost:9000",
	"us-east-1",
	"s3client-dev",
	"minioadmin",
	"minioadmin123",
	Истина,
	Ложь);
```

Поля:

- `Endpoint`: `http://localhost:9000`
- `Region`: `us-east-1`
- `Bucket`: `s3client-dev`
- `AccessKeyId`: `minioadmin`
- `SecretAccessKey`: `minioadmin123`
- `PathStyle`: `Истина`
- `UseSSL`: `Ложь`

Для CEPH Object Storage и других S3-compatible провайдеров меняются endpoint, bucket, ключи доступа и при необходимости `PathStyle`.

## Smoke-test

После загрузки общего модуля `s3Клиент` в тестовую базу выполните сценарий из `tests/minio-smoke.bsl`.

Его можно вставить во временную обработку, консоль кода или собственную тестовую обработку. Сценарий проверяет загрузку, чтение, HEAD, список объектов, presigned URL и удаление объекта.

Если вы используете не локальный MinIO, замените endpoint, bucket, регион и ключи доступа на значения своего S3-compatible провайдера.
