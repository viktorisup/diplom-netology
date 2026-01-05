# Для обновление CRDN
`
kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.0.0/deploy/crds.yaml
`
# Установка
`
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace
`
# Удаление
`
helm delete ingress-nginx --namespace ingress-nginx
`

# Helm Documentation

Please refer to the [Installation with Helm](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/) guide in the NGINX Ingress Controller documentation site.
