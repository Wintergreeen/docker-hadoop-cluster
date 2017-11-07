FROM centos
MAINTAINER kylehart@hawaii.edu

# Install java, openssh, and other tools
RUN yum clean all \
    && yum update -y \
    && yum install sudo nmap which wget openssh-server openssh-clients rsync -y \
    && yum install java-1.8.0-openjdk -y

# Install Hadoop
COPY scripts/hadoop-2.8.1.tar.gz /

RUN mkdir /opt/hadoop \
    && tar -xzf hadoop-2.8.1.tar.gz \
    && rm -f hadoop-2.8.1.tar.gz \
    && mv hadoop-2.8.1 /opt/hadoop

# Create User and get permissions
RUN useradd hadoop \
    && chown -R hadoop /opt/hadoop

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk
ENV HADOOP_PREFIX=/opt/hadoop/hadoop-2.8.1
ENV HADOOP_COMMON_HOME=/opt/hadoop/hadoop-2.8.1
ENV HADOOP_HDFS_HOME=/opt/hadoop/hadoop-2.8.1
ENV HADOOP_MAPRED_HOME=/opt/hadoop/hadoop-2.8.1
ENV YARN_HOME=/opt/hadoop/hadoop-2.8.1

# Include Hadoop executables into PATH
ENV PATH=$PATH:$HADOOP_COMMON_HOME/bin
ENV PATH=$PATH:$HADOOP_COMMON_HOME/sbin

# Copy in config files
COPY scripts/*.xml $HADOOP_PREFIX/etc/hadoop/

# Make sure hadoop-env config doens't reset JAVA_HOME
RUN echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' >> $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# Copy Bootstrap script into container
RUN mkdir /init
COPY scripts/bootstrap.sh /init/.
RUN chmod 755 /init/bootstrap.sh

# Fix SSHD config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
    && sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

# Get SSH Keys
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa \
    && /usr/sbin/sshd

# HDFS Required ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# YARN Required ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
# SSH
EXPOSE 22

CMD ["/bin/bash"]
