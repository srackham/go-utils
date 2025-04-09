test:
	go test ./...

check-for-updates:
	./copy-updates.sh -n ~/projects .
