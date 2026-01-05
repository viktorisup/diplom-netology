### Добовляем репо
`
helm repo add longhorn https://charts.longhorn.io
`
### Обновляем репы
`
helm repo update
`
### Устанавливаем
`
helm install longhorn longhorn/longhorn -n longhorn-system --create-namespace
`
### Создаем хеш проля в формате apr1 
`
echo -n 'passsword' | openssl passwd -stdin -apr1
`
получившуюся строку вставляем в манифест basic-auth-secret поселе user:
### Применяем манифесты
`
kubectl apply -f .\basic-auth-secret.yml
`
`
kubectl apply -f .\ingress.yml
`
`
kubectl apply -f .\storageclass_nfs_rwx.yml
`
`
kubectl apply -f .\storageclass_xfs.yml 
`
### Для того чтобы работал режим RWX
На каждой ноде устанавливаем 
`
apt-get install nfs-common
`
Далее применяем манифест
`
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.9.0/deploy/prerequisite/longhorn-nfs-installation.yaml
`