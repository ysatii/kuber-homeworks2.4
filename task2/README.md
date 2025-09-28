

# Задание 2. Запустить две версии в разных неймспейсах

1. Подготовив чарт, необходимо его проверить. Запуститe несколько копий приложения.
2. Одну версию в namespace=app1, вторую версию в том же неймспейсе, третью версию в namespace=app2.
3. Продемонстрируйте результат.

# Решение 2

## Подготовка 
создаем 
### values-v1.yaml
```
nginx:
  tag: "1.25-alpine"
```

### values-v1.yaml
```
nginx:
  tag: "1.26-alpine"
```
в томже каталоге что и /task2/webapp/
Нужны для того, чтобы запускать один и тот же чарт с разными версиями образа nginx, показывает что у нас могут быть разные версии дляразных сред например test и prod

## 1. Старт minikube и неймспейсы
```
minikube start
kubectl create ns app1
kubectl create ns app2
```
---

## 2. Установим две копии в app1 (две разные версии, два разных NodePort)
```
cd kuber-homeworks2.4-main/task2
```

### app1, релиз v1 → NodePort 30081
helm upgrade --install webapp-v1 ./webapp -n app1 \
  -f values-v1.yaml \
  --set service.type=NodePort \
  --set service.nodePort=30081

### app1, релиз v2 → NodePort 30082
```
helm upgrade --install webapp-v2 ./webapp -n app1 \
  -f values-v2.yaml \
  --set service.type=NodePort \
  --set service.nodePort=30082
```
![Скриншот 9](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_9.jpg)  
---

## 3. Установить третью копию в app2 (v1, свой NodePort)
### app2, релиз v1 → NodePort 30083
```
helm upgrade --install webapp-v1 ./webapp -n app2 \
  -f values-v1.yaml \
  --set service.type=NodePort \
  --set service.nodePort=30083
```
---

## 4. Проверка что установлено
### Ресурсы и сервисы
```
kubectl get all,svc -n app1
kubectl get all,svc -n app2
```
---

### 5. Релизы
```
helm list -n app1
helm list -n app2
```
![Скриншот 10](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_10.jpg)  
---

## 6. Curl изнутри (через multitool → сервис каждого релиза)
### app1, релиз v1
```
POD1=$(kubectl get pods -n app1 -l app.kubernetes.io/name=webapp-multitool,app.kubernetes.io/instance=webapp-v1 -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n app1 "$POD1" -- curl -s http://webapp-v1-webapp:80
```

### app1, релиз v2
```
POD2=$(kubectl get pods -n app1 -l app.kubernetes.io/name=webapp-multitool,app.kubernetes.io/instance=webapp-v2 -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n app1 "$POD2" -- curl -s http://webapp-v2-webapp:80
```

### app2, релиз v1
```
POD3=$(kubectl get pods -n app2 -l app.kubernetes.io/name=webapp-multitool,app.kubernetes.io/instance=webapp-v1 -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n app2 "$POD3" -- curl -s http://webapp-v1-webapp:80
```
---

## 7. Доступ снаружи (через NodePort)
```
IP=$(minikube ip)
```
### app1
```
curl "http://$IP:30081"   # webapp-v1 (app1)
curl "http://$IP:30082"   # webapp-v2 (app1)
```

### app2
```
curl "http://$IP:30083"   # webapp-v1 (app2)
```
---

## 8. Информация о релизах и сервисах

### Посмотреть назначенные порты для сервисов:
```
kubectl get svc -n app1
kubectl get svc -n app2
```

### Посмотреть текущие значения релиза:
```
helm get values webapp-v1 -n app1
helm get values webapp-v1 -n app2
helm get values webapp-v2 -n app1
```
---

## 9. список релизов Helm (во всех ns):
```
helm list -A | grep webapp
```
![Скриншот 11](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_11.jpg) 
---

## 10. Удаление 
```
helm uninstall webapp-v1 -n app1
helm uninstall webapp-v2 -n app1
helm uninstall webapp-v1 -n app2
kubectl delete ns app1 app2
```




![Скриншот 12](https://github.com/ysatii/kuber-homeworks2.4/blob/main/img/img_12.jpg) 