# Container image for the AI Studio web app.
#
# The Python production backend runs separately (see my-video-app/backend);
# this image packages only the Next.js front end.

FROM node:22-alpine AS deps
WORKDIR /app
RUN corepack enable && corepack prepare yarn@1.22.22 --activate
COPY my-video-app/package.json my-video-app/yarn.lock ./
RUN yarn install --frozen-lockfile --ignore-scripts

FROM node:22-alpine AS build
WORKDIR /app
RUN corepack enable && corepack prepare yarn@1.22.22 --activate
COPY --from=deps /app/node_modules ./node_modules
COPY my-video-app/ ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN yarn build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000
RUN addgroup -S studio && adduser -S studio -G studio
COPY --from=build --chown=studio:studio /app/.next/standalone ./
COPY --from=build --chown=studio:studio /app/.next/static ./.next/static
COPY --from=build --chown=studio:studio /app/public ./public
USER studio
EXPOSE 3000
CMD ["node", "server.js"]
