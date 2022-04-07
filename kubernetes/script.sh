kubectl create clusterrolebinding azure-devops-role-binding-svc --clusterrole=create-deployments --serviceaccount=default:azure-devops-svc

kubectl config view --minify -o jsonpath={.clusters[0].cluster.server}

kubectl get serviceAccounts azure-devops-svc -o=jsonpath={.secrets[*].name}

kubectl get secret <name here> -o json
