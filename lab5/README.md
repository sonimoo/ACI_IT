# Лабораторная работа №5. Расширенный пайплайн в GitLab CI для Laravel
 
 - **Калинкова София, I2302** 
 - **14.11.2025** 

## Цель работы

Получить практический опыт настройки собственного CI/CD-сервера с GitLab Community Edition и реализации конвейера для Laravel-приложения, включая тестирование, сборку Docker-образа и (опционально) деплой. Установка GitLab CE, создание проекта с `.gitlab-ci.yml`, настройка Runner и запуск пайплайна.

### Шаги выполнения:

#### 1. Развертывание GitLab CE
- Поднимаем виртуальную машину с Ubuntu 24.04 Server (через VirtualBox с 8 GB RAM и 4 ядрами).
- Устанавливаем GitLab CE через Docker:

  ```bash
	docker run -d \
	  --hostname 192.168.0.148 \
	  -p 80:80 \
	  -p 443:443 \
	  -p 8022:22 \
	  --name gitlab \
	  -e GITLAB_OMNIBUS_CONFIG="external_url='http://192.168.0.148'; gitlab_rails['gitlab_shell_ssh_port']=8022" \
	  -v gitlab-data:/var/opt/gitlab \
	  -v ~/gitlab-config:/etc/gitlab \
	  gitlab/gitlab-ce:latest
  ```

![alt text](img/image.png)
![alt text](img/image-1.png)

- Ждем некоторое время
- Открываем браузер на `http://192.168.0.148`.

- Проверяем пароль для `root` 

  ```bash
  docker exec -it gitlab cat /etc/gitlab/initial_root_password
  ```
  ![alt text](img/image-2.png)
  ![alt text](img/image-3.png)
  ![alt text](img/image-4.png)


#### 2. Настройка Runner
- GitLab не имеет встроенных Runner'ов, поэтому зарегистрируем его на той же VM.

- Установка GitLab Runner:
  ```bash
  curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
  sudo apt-get install -y gitlab-runner
  ```
  ![alt text](img/image-5.png)

- Зарегистрируем Runner:
  - В GitLab переходим в **Admin Area > CI/CD > Runners > New instance runner**.
  - Заполнили поля (Description, Tags, Executor — выберите "docker"), нажмите **Create runner**.
  ![alt text](img/image-6.png)

  - Поставили галочку возле Run untagged jobs
  - Скопировали **Authentication Token** (с префиксом `glrt-`).

  - Выполняем регистрацию:

    ```bash
    gitlab-runner register \
      --url "http://<vm_ip>:8080" \
      --token "<your_authentication_token>" \
      --executor "docker" \
      --docker-image "php:8.2-cli" \
      --description "laravel-runner"
      
    gitlab-runner run
    ```
    ![alt text](img/image-7.png)
    ![alt text](img/image-8.png)

  - Убедитесь, что Runner активен: `sudo gitlab-runner status`.


#### 3. Создание проекта и репозитория в GitLab

- Создаем новый проект: **Repository > New > Create blank project** (`laravel-app`).
![alt text](img/image-9.png)
![alt text](img/image-10.png)

- Клонируем репозиторий локально:
  ```bash
  git clone http://192.168.100.75:8080/root/laravel-app.git ~/laravel-app
  cd ~/laravel-app
  ```
  ![alt text](img/image-11.png)
- Настраиваем Laravel-проект:
  - Скачиваем Laravel-проект в другую папку https://github.com/laravel/laravel и копируем содержимое с папку с проектом

```bash
cp laravel/* laravel-app/ -r
```

![alt text](img/image-12.png)


  - Создаем `Dockerfile` для сборки:
    ```dockerfile
    # Используем официальный образ PHP с Apache
    FROM php:8.2-apache

    # Устанавливаем зависимости
    RUN apt-get update && apt-get install -y \
        libpng-dev libonig-dev libxml2-dev \
        && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath

    # Устанавливаем Composer
    COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

    # Копируем код приложения
    COPY . /var/www/html
    RUN composer install --no-scripts --no-interaction
    RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
    RUN chmod -R 775 /var/www/html/storage

    # Настраиваем Apache
    RUN a2enmod rewrite
    EXPOSE 80

    CMD ["apache2-foreground"]
    ```

    ![alt text](img/image-13.png)

  - Создаем `.env.testing` для тестов (например, с пустой базой данных):
    ```env
	APP_NAME=Laravel
	APP_ENV=testing
	APP_KEY=
	APP_DEBUG=true
	APP_URL=http://localhost
	APP_LOCALE=en
	APP_FALLBACK_LOCALE=en
	APP_FAKER_LOCALE=en_US
	APP_MAINTENANCE_DRIVER=file
	# APP_MAINTENANCE_STORE=database
	PHP_CLI_SERVER_WORKERS=4
	BCRYPT_ROUNDS=12
	LOG_CHANNEL=stack
	LOG_STACK=single
	LOG_DEPRECATIONS_CHANNEL=null
	LOG_LEVEL=debug
	DB_CONNECTION=mysql
	DB_HOST=mysql
	DB_PORT=3306
	DB_DATABASE=laravel_test
	DB_USERNAME=root
	DB_PASSWORD=root
	SESSION_DRIVER=database
	SESSION_LIFETIME=120
	SESSION_ENCRYPT=false
	SESSION_PATH=/
	SESSION_DOMAIN=null
	BROADCAST_CONNECTION=log
	FILESYSTEM_DISK=local
	QUEUE_CONNECTION=database
	CACHE_STORE=database
	# CACHE_PREFIX=
	MEMCACHED_HOST=127.0.0.1
	REDIS_CLIENT=phpredis
	REDIS_HOST=127.0.0.1
	REDIS_PASSWORD=null
	REDIS_PORT=6379
	MAIL_MAILER=log
	MAIL_SCHEME=null
	MAIL_HOST=127.0.0.1
	MAIL_PORT=2525
	MAIL_USERNAME=null
	MAIL_PASSWORD=null
	MAIL_FROM_ADDRESS="hello@example.com"
	MAIL_FROM_NAME="${APP_NAME}"
    ```
  - Добавляем тесты ( был тест но решила поменять, простой тест в `tests/Unit/ExampleTest.php`):
    ```php
    <?php
    namespace Tests\Unit;
    use PHPUnit\Framework\TestCase;
    class ExampleTest extends TestCase
    {
        public function testBasicTest()
        {
            $this->assertTrue(true);
        }
    }
    ```
    был тест но решила поменять

  - Создаем `.gitlab-ci.yml` в корне проекта:
    ```yaml
	stages:
	  - test
	  - build
	services:
	  - mysql:8.0
	variables:
	  MYSQL_DATABASE: laravel_test
	  MYSQL_ROOT_PASSWORD: root
	  DB_HOST: mysql
	test:
	  stage: test
	  image: php:8.2-cli
	  before_script:
	    - apt-get update -yqq
	    - apt-get install -yqq libpng-dev libonig-dev libxml2-dev libzip-dev unzip git
	    - docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath
	    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
	    - composer install --no-scripts --no-interaction
	    - cp .env.testing .env
	    - php artisan key:generate
	    - php artisan migrate --seed
	    - cp .env .env.testing
	    - php artisan config:clear
	  script:
	    - vendor/bin/phpunit
	  after_script:
	    - rm -f .env

    ```

    ![alt text](img/image-14.png)
  - Закоммитили и пушим:
    ```
    git add .
    git commit -m "Add Laravel app with CI/CD config"
    git push -u origin main
    ```
![alt text](img/image-15.png)

#### 4. Запуск и проверка конвейера

- Переходим в **CI/CD > Pipelines** в проекте.
- Пайплайн запустится автоматически. Статус изменится с `pending` на `running`.
![alt text](img/image-16.png)
- Проверьте логи каждого job (`test` и `build`):
  - `test`: Должен пройти PHPUnit-тест.

![alt text](img/image-17.png)
![alt text](img/image-18.png)

#### 5. Итог проверки
- У вас должен быть работающий GitLab с проектом Laravel, где пайплайн выполняет тесты (PHPUnit).
- Проверьте **Packages & Registries > Container Registry** — образ должен быть доступен. (нет.)
![alt text](img/image-25.png) 
- История пайплайнов отобразится в **CI/CD > Pipelines**.
![alt text](img/image-19.png)

##### несчастные попытки 
ГРУСТЬ ТОСКА НЕВЕРОЯТНАЯ
![alt text](img/image-20.png)
билд не билдится,
![alt text](img/image-21.png)
я пыталась, правда
![alt text](img/image-23.png)


![alt text](img/image-27.png)
Ошибка возникла из-за того, что GitLab Runner пытался подключиться к Registry по HTTPS, но на указанном порту сервер не обслуживает HTTPS-запросы. В результате соединение было отклонено (connection refused), и авторизация не состоялась.

![alt text](img/image-26.png)

Пробовала менять настройки и в Runner’е, и в Docker daemon, и запускать через dind, и корректировать Dockerfile — сделала всё, что могла (но видимо не могла), но проблема всё равно оставалась.

## Вывод

В ходе работы был развёрнут GitLab CE, настроен Runner и создан пайплайн для Laravel-проекта. Тестовая стадия выполнялась успешно, а при сборке Docker-образа возникли проблемы с подключением к Registry. Несмотря на попытки исправить конфигурацию, удачной сборки добиться не удалось, но цель — получить практический опыт работы с GitLab CI/CD — была выполнена.
