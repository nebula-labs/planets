aura-juno:
	bash network/build-network.sh -ajr
	bash network/start-network.sh aura juno

build-env:
	docker image build -t intertravel/env -f Dockerfile.environment --progress plain .