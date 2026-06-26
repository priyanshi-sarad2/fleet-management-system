export const environment = {
  production: true,
  // Overwritten at build time by the CodeBuild buildspec using the API_URL env var,
  // e.g. apiUrl: 'https://fleetman-api.priyanshiseniordevops.online'
  apiUrl: ''
};
