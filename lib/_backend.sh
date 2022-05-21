#!/bin/bash
# 
# functions for setting up app backend

#######################################
# creates mysql db using docker
# Arguments:
#   None
#######################################
backend_mysql_create() {

  local db_port="$1"
  local db_name="$2"
  local db_pass="$3"

  print_banner
  printf "${WHITE} 💻 Criando banco de dados...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  docker run --name ${db_name} \
                -e MYSQL_ROOT_PASSWORD=${mysql_root_password} \
                -e MYSQL_DATABASE=${db_name} \
                -e MYSQL_USER=${db_user} \
                -e MYSQL_PASSWORD=${db_pass} \
             --restart always \
                -p ${db_port}:3306 \
                -d mariadb:latest \
             --character-set-server=utf8mb4 \
             --collation-server=utf8mb4_bin
EOF

  sleep 2
}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {

  local port="$1"
  local db_name="$2"
  local db_pass="$3"
  local frontend_url="$4"
  local backend_url="$5"

  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  jwt_secret=$(openssl rand -base64 32)
  jwt_refresh_secret=$(openssl rand -base64 32)

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/whaticket/$frontend_url/backend/.env
NODE_ENV=
BACKEND_URL=https://${backend_url}
FRONTEND_URL=https://${frontend_url}
PROXY_PORT=443
PORT=${port}

DB_HOST=localhost
DB_DIALECT=
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
[-]EOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {

  local frontend_url="$1"

  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket/$frontend_url/backend
  npm install
EOF

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {

  local frontend_url="$1"

  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket/$frontend_url/backend
  npm install
  npm run build
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket
  git pull
  cd /home/deploy/whaticket/backend
  npm install
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:seed
  pm2 restart all
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {

  local frontend_url="$1"

  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket/$frontend_url/backend
  npx sequelize db:migrate
EOF

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {

  local frontend_url="$1"

  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket/$frontend_url/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {

  local frontend_url="$1"
  local backend_url="$2"

  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/whaticket/$frontend_url/backend
  pm2 start dist/server.js --name $backend_url
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {

  local port="$1"
  local backend_hostname="$2"

  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/sites-available/$backend_hostname << 'END'
server {
  server_name $backend_hostname;

  location / {
    proxy_pass http://127.0.0.1:$port;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END

ln -s /etc/nginx/sites-available/$backend_hostname /etc/nginx/sites-enabled
EOF

  sleep 2
}

#######################################
# compiles sequelize config file
# Arguments:
#   None
#######################################
backend_make_sequelize_config_file() {

  local db_port="$1"

  print_banner
  printf "${WHITE} 💻 Compilando sequelize config file (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy << EOF

cat > /home/deploy/whaticket/$frontend_url/backend/src/config/database.ts << 'END'
require("../bootstrap");

module.exports = {
  define: {
    charset: "utf8mb4",
    collate: "utf8mb4_bin"
  },
  dialect: process.env.DB_DIALECT || "mysql",
  timezone: "-03:00",
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASS,
  port: ${db_port},
  logging: false
};
END

EOF

  sleep 2
}
