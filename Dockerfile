FROM ubuntu:24.04

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# Base packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    unzip \
    git \
    jq \
    fzf \
    gnupg \
    build-essential \
    gcc \
    python3 \
    pipx && \
    rm -rf /var/lib/apt/lists/*

# Validation of Git, GCC, Python3 interpreter and pipx presence
RUN git --version
RUN gcc --version
RUN python3 --version
RUN pipx --version

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN uv --version

# OpenTofu
RUN curl --proto '=https' --tlsv1.2 -fsSL \
    https://get.opentofu.org/install-opentofu.sh \
    -o install-opentofu.sh && \
    chmod +x install-opentofu.sh && \
    ./install-opentofu.sh --install-method standalone && \
    rm -f install-opentofu.sh

    RUN tofu version

# Ansible
ARG ANSIBLE_CORE_VERSION=2.16.0

RUN pipx install ansible-core==${ANSIBLE_CORE_VERSION}

RUN ansible --version

# kubectl
ARG KUBECTL_VERSION=v1.37.0

RUN curl -LO \
"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
rm -f kubectl

RUN kubectl version --client -o yaml

# Krew (plugin manager for kubectl)
RUN set -x; cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    KREW="krew-${OS}_${TARGETARCH}" && \
    curl -fsSLO \
    "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew

RUN kubectl krew update

RUN kubectl krew version

# Helm
RUN curl -fsSL -o get_helm.sh \
    https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

RUN helm version --client

# KubeNS
RUN curl -sS https://webi.sh/kubens | sh

RUN kubens --version

# ArgoCD
ARG ARGOCD_VERSION=v3.5.2

RUN curl -sSL -o argocd-linux-${TARGETARCH} \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${TARGETARCH}" && \
    install -m 555 argocd-linux-${TARGETARCH} /usr/local/bin/argocd && \
    rm argocd-linux-${TARGETARCH}

RUN argocd version --client -o yaml

# Cilium
ARG CILIUM_CLI_VERSION=v0.19.7

RUN curl -L --fail --remote-name-all \
    "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${TARGETARCH}.tar.gz" && \
    tar xzvfC cilium-linux-${TARGETARCH}.tar.gz /usr/local/bin && \
    rm cilium-linux-${TARGETARCH}.tar.gz

RUN cilium version --client

# Hubble
ARG HUBBLE_VERSION=v1.19.4

RUN curl -L --fail --remote-name-all \
    "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-${TARGETARCH}.tar.gz" && \
    tar xzvfC hubble-linux-${TARGETARCH}.tar.gz /usr/local/bin && \
    rm hubble-linux-${TARGETARCH}.tar.gz
    
RUN hubble version --client

# CNPG plugin
RUN kubectl krew install cnpg

RUN kubectl cnpg version

CMD ["/bin/bash"]
