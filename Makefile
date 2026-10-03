.PHONY: up down status test

up:      ## create a local kind cluster and let Argo CD install everything
	kind create cluster --config cluster/kind.yaml
	bash bootstrap/install.sh
	bash tests/wait-for-apps.sh 1500

down:
	kind delete cluster --name serwis

status:
	kubectl -n argocd get applications.argoproj.io

test:
	bash tests/smoke.sh
