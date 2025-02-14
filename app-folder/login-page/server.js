// server.js
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.static('public')); // Serve static files from 'public' directory
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html')); // Serve index.html for all other requests
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
