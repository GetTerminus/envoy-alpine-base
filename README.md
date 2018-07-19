# envoy-alpine-base - A Container to run Envoy and whatever else you desire.

Purpose
---
[Envoy is an open source edge and service proxy, designed for cloud-native applications.](https://www.envoyproxy.io/)<br/>
Envoy uses a mostly dynamic configuration for proxying requests. This helps Envoy facilitate service discovery.<br/>
This project's purpose is to provide a container that will run Envoy along side your application.

Running Envoy in an application's container removes the need for the application to be aware of the URLs for external services. Instead, the application can either programmatically generate service URLs based on a predefined format, or it can be configured to use a set of reasonable defaults that Envoy will resolve.

How It Works
---
This method of running Envoy consists of running it as another process in an application's container. To achieve this, and to properly handle signals, the Docker container needs to have an init system, and a process manager.

The init system is responsible for running as PID 1, and forwarding SIGINT, SIGTERM, and other signals to the child processes, and reaping zombies. Docker recommends using [tini](https://github.com/krallin/tini).

The process manager is responsible for ensuring that both Envoy and your application are running. It is also responsible for stopping the container should either fail to start. For this, [Docker recommends](https://docs.docker.com/config/containers/multi-service_container/) [supervisord](http://supervisord.org/).

The `ENTRYPOINT` in this container is the init system, `CMD` is the startup command for Supervisord.

Getting Started
---
Using Envoy with your application will require a few changes. The depth of the changes depends on the specific implementation of your application.

### Running Your Application with Supervisord
To configure your application to run via Supervisord, you will need to perform the following actions.

1. Create the following directory structure in your repo
    ```
    etc
    ├── envoy
    │   └── envoy.yaml.j2
    └── supervisor
        └── conf.d
           └── {app_name}.ini
    ```

2. Create an ini file that tells Supervisord how to run your application, and what to do if the application dies horribly. Environment variables passed to the container will be read by the application.</br>
See http://supervisord.org/configuration.html#program-x-section-settings for more information on the format of this ini file.
    ``` ini
    # {app_name}.ini
    [program:{app_name}]
    # env vars must use the format %(ENV_<ENV_VAR>)s
    command=/path/to/the/app
            --with-flags=%(ENV_APP_VAR)s
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/dev/stderr
    stderr_logfile_maxbytes=0

    [eventlistener:{app_name}_exit]
    command=command_executor.py supervisorctl shutdown
    process_name={app_name}
    events=PROCESS_STATE_FATAL
    ```
    **Note**:
    * It is important to include a listener for your application. The listener will call a script to stop Supervisord should your application be unable to run. This will allow the container to exit if an error is encountered.
    * Supervisor does not support starting a program after another has finished. In order to work around this, create a listener to listen for `PROCESS_STATE_EXITED` on a program that calls the start command for the next program. An example of this can be found in [envoy.ini](etc/supervisor/conf.d/envoy.ini)

3. Create a config file for envoy named `etc/envoy/envoy.yaml.j2`. This file will be interpolated using Jinja2 and written out as `etc/envoy/envoy.yaml`.</br>
   For more information about configuring Envoy, [read the docs](https://www.envoyproxy.io/docs/envoy/v1.7.0/).

4. Update your Dockerfile to use the [envoy-alpine-base container](https://hub.docker.com/r/getterminus/envoy-alpine-base/)
    ``` Dockerfile
    # Start from the Terminus Envoy container
    # Be sure to specify the tag, which can be found at https://hub.docker.com/r/getterminus/envoy-alpine-base/
    FROM getterminus/envoy-alpine-base

    # Assuming your application is built in the `build` dir
    # Copy your application to the container
    COPY build/app /opt/

    # Assuming your repo has the same etc directory structure listed above
    # Copy the config files for supervisord
    COPY etc/ /etc/

    # There is no need to set an entrypoint or cmd, and there is no need for a startup script
    ```
