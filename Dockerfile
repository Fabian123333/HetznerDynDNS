FROM debian:10

RUN apt-get update
RUN apt-get install -y            \
				curl              \	
				ca-certificates   \
				dnsutils          \
				jq                \
			2>&1 > /dev/null

#RUN apt-get clean

ADD ./entrypoint.sh /entrypoint.sh
                                  
ENTRYPOINT /entrypoint.sh
