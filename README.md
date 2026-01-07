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

Я решил развернуть кластер через kubespray, с некоторой особенностью через NAT.
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
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/id_ed25519_home
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

**Так как часть с терраформом я сделал в Яндекс облаке как требовалось , дальше я буду делать все на своем кластере для экономии средств**

**Файлы для настройки K8S**

```
https://github.com/viktorisup/diplom-netology/tree/main/k8s-configs
```

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

**Http доступ на 80(443) порту к web интерфейсу grafana**

```
https://grafana.isupit.ru
```

**Скриншот дажборда графаны**

![](screenshots/grafana.png)

**Http доступ на 80(443) порту к тестовому приложению**

```
https://myapp.isupit.ru/
```

**установка Atlantis**

Вам зарание надо установить какого либо provisioner для выделения pv. Я выбрал longhorn, в ридми описано как его установить. Либо в ручную создать storage class и pv.

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
helm install atlantis runatlantis/atlantis -f values.yaml -n atlantis
```
Далее настраиваем проки сервер с tls терминацией(nginx) , который будет проксировать запросвы с наружи на сервис lb. Можно через ингрес или сервис nodeport. После того как есть доступ до Атлантиса из интернета , можно переходить к настройке самого атлантиса.
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

После инсталяции приложения не сразу все заработало пришлось в настройке приложения GH указать тот же вебхук-секрет что и при установке чарта. Еще добавил креды в values которые были созданы при установке приложения. Еще создать и прокинуть секреты для YC. После обновить чарт

Создание секрета доступ к s3
```
kubectl -n atlantis create secret generic yc-s3-creds-aws --from-literal=AWS_ACCESS_KEY_ID='xxxxxxxxxx' --from-literal=AWS_SECRET_ACCESS_KEY='xxxxxxxxxx'
```
Создание секрета ключа доступа к ЯО
```
kubectl -n atlantis create secret generic yc-sa-key --from-file=authorized_key.json="/root/.authorized_key.json"
```
Правка values (все изменения)
```
orgAllowlist: "github.com/viktorisup/*"

github:
  user: "viktorisup"
  token: "xxxxx"
  secret: "xxxx"
  hostname: "github.com"

githubApp:
  id: "12345678"
  installationId: "12345678"
  slug: atlantis
  key: |
    -----BEGIN PRIVATE KEY-----
    xxxx
    -----END PRIVATE KEY-----
  secret: xxxxx

environment:
  YC_SERVICE_ACCOUNT_KEY_FILE: /var/run/yc/authorized_key.json

extraVolumes:
  - name: yc-sa-key
    secret:
      secretName: yc-sa-key

extraVolumeMounts:
  - name: yc-sa-key
    mountPath: /var/run/yc
    readOnly: true

environmentSecrets:
  - name: AWS_ACCESS_KEY_ID
    secretKeyRef:
      name: yc-s3-creds-aws
      key: AWS_ACCESS_KEY_ID
  - name: AWS_SECRET_ACCESS_KEY
    secretKeyRef:
      name: yc-s3-creds-aws
      key: AWS_SECRET_ACCESS_KEY
```
После чего обновляем чарт

```
helm upgrade atlantis runatlantis/atlantis -f /root/netology/values.yaml -n atlantis
```
**Скриншот коментариев Атлантис в PR**

![](screenshots/pr_atlantis.png)

**Скриншот отработанного плана**

![](screenshots/apply_atlantis.png)

### Установка и настройка CI/CD

Я настроил CI/CD через Teamcity

**Интерфейс ci/cd сервиса доступен по http**

```
https://teamcity.isupit.ru
```

**Скриншоты успешных сборок и деплоя**

![](screenshots/teamcity-build.png)

![](screenshots/teamcity-deploy.png)

