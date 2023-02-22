create-universe:
	@echo "CREATING UNIVERSE"
	bash network/build-network.sh
	@echo "DONE"

let-there-be-light:
	@echo "LET THERE BE LIGHT"
	bash network/start-network.sh
	@echo "AND THERE WAS LIGHT"