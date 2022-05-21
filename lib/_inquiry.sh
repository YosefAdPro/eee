#!/bin/bash

FRONTEND_URLS=()
BACKEND_URLS=()

DB_NAMES=()
DB_PASSWORDS=()

available_port=0

available_ports_from() {

	testing_port=$1

	if [ exec 6<>/dev/tcp/127.0.0.1/$testing_port ]; then
		available_ports_from `expr $testing_port + 1`
	fi

  available_port=$testing_port
}

get_frontend_url() {
  local db_password=$(openssl rand -base64 32)
  
  print_banner
  printf "${WHITE} 💻 Digite o domínio da interface web:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " frontend_url

  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}

  FRONTEND_URLS+=($frontend_url)

  DB_NAMES+=($frontend_url)
  DB_PASSWORDS+=($db_password)
}

get_backend_url() {
  
  print_banner
  printf "${WHITE} 💻 Digite o domínio da sua API:${GRAY_LIGHT}"
  printf "\n\n"
  read -p "> " backend_url

  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}

  BACKEND_URLS+=($backend_url)
}

get_urls() {
  
  get_frontend_url
  get_backend_url
}

software_update() {
  
  frontend_update
  backend_update
}

inquiry_options() {
  
  print_banner
  printf "${WHITE} 💻 O que você precisa fazer?${GRAY_LIGHT}"
  printf "\n\n"

  # prints added instances
  if [ ! ${#FRONTEND_URLS[@]} -eq 0 ]; then
    for index in "${!FRONTEND_URLS[@]}"; do
      printf " + ${FRONTEND_URLS[index]} → ${BACKEND_URLS[index]} \n"
    done
    printf "\n"
    printf "   [1] Adicionar Instância\n"
    printf "   [2] Instalar Instâncias Adicionadas\n"
    printf "   [3] Atualizar\n"
    printf "   [4] Sair\n"
  
    printf "\n"
    read -p "> " option

    case "${option}" in
      1) 
        get_urls 
        inquiry_options
        ;;

      2) ;;

      3) 
        software_update 
        exit
        ;;

      *) exit ;;
    esac
  else
    printf "   [1] Adicionar Instância\n"
    printf "   [2] Atualizar\n"
    printf "   [3] Sair\n"
  
    printf "\n"
    read -p "> " option

    case "${option}" in
      1) 
        get_urls 
        inquiry_options
        ;;

      2) 
        software_update 
        exit
        ;;

      *) exit ;;
    esac
  fi
}

