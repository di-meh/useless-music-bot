# TODO: change to alpine once mediaplex is available for alpine
# see: https://github.com/androzdev/mediaplex/issues/9
FROM node:lts-bullseye-slim as base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
RUN apt-get update && apt-get install -y ffmpeg && apt-get clean

# Install dependencies
FROM base as build
COPY . /home/node/app
WORKDIR /home/node/app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

## Copy the music bot and web app to separate directories
## and run them in development mode
#FROM build as deploy-dev
#RUN ["pnpm", "deploy", "--filter=music-bot-app", "/home/node/music-bot-dev"]
#RUN ["pnpm", "deploy", "--filter=web", "/home/node/web-dev"]

FROM build as music-bot-dev
WORKDIR /home/node/app
EXPOSE 5000
CMD ["pnpm", "bot", "dev"]

FROM build as web-dev
WORKDIR /home/node/app
EXPOSE 3000
CMD ["pnpm", "web", "dev"]

# Copy the music bot and web app to separate directories
# and run them in production mode
FROM build as deploy-prod
RUN ["pnpm", "build"]
RUN ["pnpm", "deploy", "--filter=music-bot-app", "--prod", "/home/node/music-bot"]
RUN ["pnpm", "deploy", "--filter=web", "--prod", "/home/node/web"]

FROM base as music-bot
COPY --from=deploy-prod /home/node/music-bot /home/node/music-bot
WORKDIR /home/node/music-bot
CMD ["pnpm", "start"]

FROM base as web
COPY --from=deploy-prod /home/node/web /home/node/web
WORKDIR /home/node/web
CMD ["pnpm", "start"]