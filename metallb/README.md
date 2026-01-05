# Устанавливаем через манифест
`
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
`
**актуальная версия манифеста**

https://metallb.io/installation/ 

# Применяем конфиг с ip pool
`
kubectl apply -f metallb-config.yml
`