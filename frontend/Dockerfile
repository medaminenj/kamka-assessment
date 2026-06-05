# ===========================
# Stage 1 — Build Angular
# ===========================
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install --silent

COPY . .
RUN npm run build -- --configuration production

# ===========================
# Stage 2 — Serve with Nginx
# ===========================
FROM nginx:alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/noteflow-frontend/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
