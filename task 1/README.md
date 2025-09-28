 # Задание 1. Подготовить Helm-чарт для приложения

1. Необходимо упаковать приложение в чарт для деплоя в разные окружения. 
2. Каждый компонент приложения деплоится отдельным deployment’ом или statefulset’ом.
3. В переменных чарта измените образ приложения для изменения версии.

------
## Решение 1

сделаем задание на основе предыдуще й работы  https://github.com/ysatii/kuber-homeworks2.3/tree/main/task1 1 

### Структура чарта

# Helm-чарт для ДЗ (на основе task1)

Ниже — полностью готовая «рыба» чарта, который упаковывает приложение из `task1`, **разделяя компоненты** на отдельные Deployment'ы (требование ДЗ) и позволяя **менять версии образов через values**. Просто скопируй структуру и содержимое файлов.

---

## 1. Структура чарта

```
webapp/
├─ Chart.yaml
├─ values.yaml
└─ templates/
   ├─ _helpers.tpl
   ├─ configmap.yaml
   ├─ deployment-nginx.yaml
   ├─ deployment-multitool.yaml
   └─ service.yaml
```

---

## 2. Листинг файла  `Chart.yaml`

```yaml
apiVersion: v2
name: webapp
version: 0.1.0
appVersion: "1.0.0"
description: "Helm chart for nginx + multitool split into separate Deployments"
type: application
```

---

## 3 Файл `values.yaml`

```yaml
replicaCount:
  nginx: 1
  multitool: 1

nginx:
  image: nginx
  tag: "1.25-alpine"
  containerPort: 80

multitool:
  image: wbitt/network-multitool
  tag: "alpine-3.20"
  httpPort: 1180

service:
  type: ClusterIP
  port: 80
  targetPort: 80
  nodePort: 30080

webPage: |
  <html>
    <body>
      <h1>Hello from nginx on Kubernetes!</h1>
    </body>
  </html>
```

---

## 4. Файл `templates/_helpers.tpl`

```tpl
{{- define "webapp.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "webapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```

---

## 5. Файл `templates/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "webapp.fullname" . }}-content
  labels:
    app.kubernetes.io/name: {{ include "webapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
data:
  index.html: |
{{ .Values.webPage | indent 4 }}
```

---

## 6. Файл `templates/deployment-nginx.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}-nginx
  labels:
    app.kubernetes.io/name: {{ include "webapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount.nginx }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "webapp.name" . }}-nginx
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "webapp.name" . }}-nginx
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: nginx
          image: {{ .Values.nginx.image }}:{{ .Values.nginx.tag }}
          ports:
            - containerPort: {{ .Values.nginx.containerPort }}
          volumeMounts:
            - name: web-content
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web-content
          configMap:
            name: {{ include "webapp.fullname" . }}-content
```

---

## 7. Файл `templates/deployment-multitool.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}-multitool
  labels:
    app.kubernetes.io/name: {{ include "webapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount.multitool }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "webapp.name" . }}-multitool
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "webapp.name" . }}-multitool
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: multitool
          image: {{ .Values.multitool.image }}:{{ .Values.multitool.tag }}
          env:
            - name: HTTP_PORT
              value: "{{ .Values.multitool.httpPort }}"
          ports:
            - containerPort: {{ .Values.multitool.httpPort }}
```

---

## 8. Файл `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ include "webapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    # Сервис привязываем к nginx-подам
    app.kubernetes.io/name: {{ include "webapp.name" . }}-nginx
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
{{- if eq .Values.service.type "NodePort" }}
      nodePort: {{ .Values.service.nodePort }}
{{- end }}
```

---

## 9. Быстрый локальный рендер (проверка шаблонов)

```bash
helm template webapp ./webapp > output.yaml
```
Установим  helm 
```sh
sudo snap install helm --classic
helm version
```

повторим 

```bash
helm template webapp ./webapp > output.yaml
```

---

## 10 Команды для установки  

Создай неймспейсы:
```bash
minikube start
```

```bash
kubectl create ns app1
```

Базовая установка:

```bash
helm upgrade --install webapp ./webapp -n app1
```

Смотри объекты в неймспейсе app1:

kubectl get all -n app1


Отдельно список релизов Helm (во всех ns):

helm list -A | grep webapp


Можно детальнее проверить, какие values подставились:

helm get values webapp -n app1


2. Изменение образа через values (требование ДЗ)

В values.yaml у тебя есть секция:

nginx:
  image: nginx
  tag: "1.25-alpine"


Меняешь версию образа (например, на "1.26-alpine") и обновляешь релиз:

helm upgrade webapp ./webapp -n app1


Проверка, что новая версия применена:

kubectl describe deploy webapp-webapp-nginx -n app1 | grep Image:


Удаляем что было создано 
helm uninstall webapp -n app1
kubectl delete namespace app1



ак упаковать чарт в архив

Из каталога, где лежит твой webapp/:

helm package ./webapp


На выходе появится архив:

webapp-0.1.0.tgz













### Две версии образа через разные values

`values-v1.yaml`:

```yaml
nginx:
  tag: "1.25-alpine"
```

`values-v2.yaml`:

```yaml
nginx:
  tag: "1.26-alpine"
```





Деплой по требованиям ДЗ (несколько копий):

```bash
# 1) версия v1 в app1
helm upgrade --install webapp-v1 ./webapp -n app1 -f values-v1.yaml

# 2) версия v2 в app1 (вторая копия в том же ns)
helm upgrade --install webapp-v2 ./webapp -n app1 -f values-v2.yaml

# 3) версия v1 в app2
helm upgrade --install webapp-v1 ./webapp -n app2 -f values-v1.yaml
```

Проверка/скриншоты для README:

```bash
kubectl get pods -n app1 -o wide
kubectl get svc -n app1
kubectl get pods -n app2 -o wide
kubectl get svc -n app2
helm list -n app1
helm list -n app2
```

Если используешь NodePort:

```bash
kubectl get svc -n app1
# далее curl http://<NODE_IP>:<NODE_PORT>
```

---

## 11) Чек соответствия требованиям ДЗ

* [x] **Упаковано в чарт** для деплоя в разные окружения/неймспейсы.
* [x] **Каждый компонент — отдельный Deployment**: `nginx` и `multitool` разделены.
* [x] **Версия образа меняется через values** (`nginx.tag`, `multitool.tag`).

```
```
