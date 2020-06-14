all:
	docker ps -a | awk '{ print $1,$2 }' | grep centos | awk '{print $1 }' | xargs -I {} docker rm {}
