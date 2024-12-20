#
# build image
#
IMG ?= quay.io/mobb/windows-overcommit-webhook
VERSION ?= latest
docker-build:
	@docker build -t $(IMG):$(VERSION) .

docker-push:
	@docker push $(IMG):$(VERSION)

#
# deployment-related tasks
#
certs:
	@scripts/gen-certs.sh

create:
	@kubectl apply -f manifests/deploy/namespace.yaml && \
		scripts/apply-certs.sh && \
		kubectl apply -f manifests/deploy/deploy.yaml && \
		kubectl patch validatingwebhookconfiguration windows-overcommit-webhook \
			--type=json \
			-p="$$(echo '[{"op": "replace", "path": "/webhooks/0/clientConfig/caBundle", "value": "'$$(cat tmp/ca.crt | base64 | tr -d '\n')'"}]')"

destroy:
	@kubectl delete -f manifests/deploy/deploy.yaml
	@kubectl delete -f manifests/deploy/namespace.yaml

#
# development and test related tasks
#
create-vm-ns:
	@kubectl create ns my-vms --dry-run=client -o yaml | kubectl apply -f -

destroy-vm-ns:
	@kubectl delete ns my-vms
