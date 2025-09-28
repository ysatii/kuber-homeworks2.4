 # Задание 1. Подготовить Helm-чарт для приложения

1. Необходимо упаковать приложение в чарт для деплоя в разные окружения. 
2. Каждый компонент приложения деплоится отдельным deployment’ом или statefulset’ом.
3. В переменных чарта измените образ приложения для изменения версии.

------
# Решение 1

## сделаем задание на основе предыдущей работы 
https://github.com/ysatii/kuber-homeworks2.3/tree/main/task1 
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

## 3. Файл `values.yaml`

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
  tag: "latest"
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

---
 
## 10. проверка линтером
```bash
helm lint ./webapp
```

## 11. рендеренг шаблонов
```
helm template webapp ./webapp --debug | sed -n '1,300p'
```

![Скриншот 1](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_1.jpg)
![Скриншот 2](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_2.jpg)
![Скриншот 3](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_3.jpg)


---
## 12. Команды для для упаковки чарта в архив

Из каталога, где лежит webapp/:
```bash
helm package ./webapp
```

На выходе появится архив:
webapp-0.1.0.tgz с версией! архивовв у нас два!
второй webapp-2.1.0.tgz 

```bash
minikube start
```
---
## 13. Создадим неймспейсы:
```bash
kubectl create ns app1
kubectl create ns app1
```
---
## 14. Установка:

```bash
helm install webapp ./webapp-0.1.0.tgz -n app1  
helm install webapp ./webapp-2.1.0.tgz -n app2  
```
webapp-0.1.0.tgz nodePort: 30080  
webapp-2.1.0.tgz nodePort: 30081  
  
### 15. проверим адрес ноды minikube ip 
```
192.168.49.2:30080  
192.168.49.2:30081  
```
---

### 16. ссылки на архивы с чартами
https://github.com/ysatii/kuber-homeworks2.4/blob/main/task1/webapp-0.1.0.tgz   
https://github.com/ysatii/kuber-homeworks2.4/blob/main/task1/webapp-2.1.0.tgz  


![Скриншот 4](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_4.jpg)  
![Скриншот 5](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_5.jpg)  
![Скриншот 6](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_6.jpg) 
---

## 17. Смотри объекты в неймспейсе app1 и app1:
```
kubectl get all -n app1
kubectl get all -n app2
```

Посмотреть сервисы в namespace app1 и app2
```
kubectl get svc -n app1
kubectl get svc -n app2
```

Отдельно список релизов Helm (во всех ns):
helm list -A | grep webapp
---

## 18. Можно детальнее проверить, какие values подставились:
```
helm get values webapp -n app1
helm get values webapp -n app2
```

![Скриншот 7](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_7.jpg)  
---

## 19. Проверка ответа nginx 
```
NGINX1=$(kubectl get pods -n app1 -l app.kubernetes.io/name=webapp-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n app1 "$NGINX1" -- sh -lc 'cat /usr/share/nginx/html/index.html'
```

```
NGINX2=$(kubectl get pods -n app2 -l app.kubernetes.io/name=webapp-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n app2 "$NGINX2" -- sh -lc 'cat /usr/share/nginx/html/index.html'
```
---

## 20. Удаляем что было создано 
```
helm uninstall webapp -n app1
helm uninstall webapp -n app1

kubectl delete namespace app1
kubectl delete namespace app1
```

![Скриншот 8](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_7.jpg)  
---

