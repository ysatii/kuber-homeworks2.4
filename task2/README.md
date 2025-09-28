



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
