# diplom-netology

Это репозиторий с дипломной работой по курсу DevOps инженер с нуля школы Нетология

## Цели:

Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
Запустить и сконфигурировать Kubernetes кластер.
Установить и настроить систему мониторинга.
Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
Настроить CI для автоматической сборки и тестирования.
Настроить CD для автоматического развёртывания приложения.

### Создание облачной инфраструктуры

Для того что бы терраформ сохранял свое состояние в s3 необходимо создать бакет и сервисный аккаунт для управления хранилищем. Для этого переходим в каталог infra-terraform/bootstrap и делаем 

```
terraform init
terraform apply
```

После чего сохраняем output переменные в надежное место.

Для сохранения secret_key выполнить команду

```
terraform output -json s3_secret_access_key
```

Далее создаем базовую инфраструктуру. Переходим в каталог infra-terraform/main и выполняем

```
terraform init -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"
terraform apply
```

**Скриншот состояние терраформа сохраненного в бакете**

![](screenshots/state_in_bucket.png)

### Создание Kubernetes кластера

Я решил развернуть кластер через kubespray, с некоторой особенностью через NAT
Клонируем репозиторий
```
git clone git@github.com:kubernetes-sigs/kubespray.git && cd kubespray
```
Далее правим инвентарь, но предварительно на проксирующей машине (NAT_instance) делаем правила проброса портов

**Скриншот правил iptables**

![](screenshots/iptables.png)

**Скриншот inventory**

![](screenshots/inventory.png)

Далее запускаем плейбук

```
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/id_ed25519_yc
```

Единственное не стал разбираться где в плейбуке указывать SNI и просто руками поправил ClusterConfiguration

```
kubectl -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > /root/ClusterConfiguration.yaml
```

добавил новые san

```
nano /root/ClusterConfiguration.yaml
```

Сохранил старые серты и удалил оригиналы чтоб нормально перевыпустить новые, а не renew старых

```
mkdir -p /root/pki-backup
cp -a /etc/kubernetes/ssl/apiserver.{crt,key} /root/pki-backup/
rm -f /etc/kubernetes/ssl/apiserver.crt /etc/kubernetes/ssl/apiserver.key
```

Сгенерировал сертификат заново с учетом certSANs

```
kubeadm init phase certs apiserver --config /root/ClusterConfiguration.yaml
touch /etc/kubernetes/manifests/kube-apiserver.yaml
```

Проверяем что новые san появились

```
openssl x509 -in /etc/kubernetes/ssl/apiserver.crt -noout -text | sed -n '/Subject Alternative Name/,+2p'
```

Еще уберем таинс с мастер ноды

```
# смотрим как указан параметр таинс в конфигурации 
kubectl describe node k8s-vm1 | grep Taints:
# отключаем таинс
kubectl taint nodes k8s-vm1 node-role.kubernetes.io/control-plane:NoSchedule-
```

Теперь я могу подключаться к кубу через нат инстанс

**Скриншот всех подов и нод**

![](screenshots/kube_info.png)

**Скриншот виртуалок с адресами и именами в Яндекс облаке**

![](screenshots/vm_yc.png)

###  Создание тестового приложения

**Ссылка на репозиторий**

```
https://github.com/viktorisup/deploy-app
```

**Скриншот залитого образа**

![](screenshots/docker_registry.png)

###  Подготовка cистемы мониторинга и деплой приложения

**Установка мониторинга**
Клонируем репозиторий и заходим в него 
```
git clone git@github.com:prometheus-operator/kube-prometheus.git && cd kube-prometheus
```
Устанавливаем 
```
kubectl apply --server-side -f manifests/setup
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
kubectl apply -f manifests/
```

**установка Atlantis**

создадим директорию на всех нодах для локального storage

```
mkdir -p /k8s/storage/atlantis
```

Применим манифесты k8s-configs/storage-class/sc-local.yaml и k8s-configs/pv/atlantis-pv.yaml

Установим хелм чарт Atlantis. Предварительно надо создать токен в github и дать права. 

```
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm inspect values runatlantis/atlantis > values.yaml
```
Далее указать в values значения github и orgAllowlist. Secret это рандомный стринг из 24 символов

```
# for example
github:
  user: foo
  token: bar
  secret: baz
orgAllowlist: github.com/runatlantis/*
```

Устанавливаем сам чарт

```
helm install atlantis runatlantis/atlantis -f values.yaml
```
Далее настраиваем проки сервер с tls терминацией(nginx) , который будет проксировать запросвы с наружи на сервис NodePort. Можно через ингрес или сервис loadBalancer , но в облаке у меня не получилось настроить Metallb. Так как у меня кубернетес on-prem. После того как есть доступ до Атлантиса из интернета , можно переходить к настройке самого атлантиса.
Заходим на свой Атлантис https://$ATLANTIS_HOST/github-app/setup и правим json,  example меняем на свой домен. Далее жмем setup
```
{
  "name": "Atlantis for <org-or-repo>",
  "description": "Terraform Pull Request Automation (Atlantis) at https://atlantis.example.com",
  "url": "https://atlantis.example.com",
  "redirect_url": "https://atlantis.example.com/github-app/exchange-code",
  "public": false,

  "default_events": [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
    "push"
  ],

  "default_permissions": {
    "contents": "read",
    "pull_requests": "write",
    "issues": "write",
    "checks": "write",
    "statuses": "write",
    "repository_hooks": "write",
    "members": "read"
  },

  "hook_attributes": {
    "url": "https://atlantis.example.com/events",
    "active": true
  }
}
```
Далее будет редирект на гитхаб и страничка с Github app created successfully
Креды сохраняем на всякий случай. И переходим по ссылке которую предлагает Атлантис для инсталяции приложения в GH. Далее приложение должно появится в https://github.com/settings/apps