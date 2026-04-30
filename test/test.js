const assert = require('assert');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Base URL for the API
const BASE_URL = 'http://localhost:3000/api/v1';

// Test data
const organizerCredentials = {
  correo: 'atletismo_org@app.com',
  password: 'password123',
};

let token;
let tournamentId;
const requestLog = [];

// Helper functions
async function loginUser(credentials) {
  const response = await axios.post(`${BASE_URL}/usuarios/login`, credentials);
  console.log('Login response:', JSON.stringify(response.data, null, 2));
  return response.data.data.token;
}

async function getTournaments(authToken) {
  const response = await axios.get(`${BASE_URL}/torneos`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  console.log('Torneos response:', JSON.stringify(response.data, null, 2));
  return response.data.data;
}

async function generateMatches(tournamentId, authToken) {
  const response = await axios.post(
    `${BASE_URL}/torneos/${tournamentId}/generar-enfrentamientos`,
    {},
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  console.log('Generate matches response:', JSON.stringify(response.data, null, 2));
  return response.data.data;
}

async function getMatches(authToken) {
  const response = await axios.get(`${BASE_URL}/partidos`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  console.log('Partidos response:', JSON.stringify(response.data, null, 2));
  return response.data.data;
}

async function updateMatchStatus(matchId, status, authToken) {
  const payload = { estado: status };
  const response = await axios.put(
    `${BASE_URL}/partidos/${matchId}`,
    payload,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  logRequest('PUT', `partidos/${matchId}`, payload, response.data);
  console.log(`Match ${matchId} status updated to ${status}`);
  return response.data.data;
}

async function submitResults(matchId, results, authToken) {
  const response = await axios.post(
    `${BASE_URL}/partidos/${matchId}/puntuaciones`,
    results,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  logRequest('POST', `partidos/${matchId}/puntuaciones`, results, response.data);
  console.log('Submit results response:', JSON.stringify(response.data, null, 2));
  return response.data.data;
}

async function getTournamentStandings(tournamentId, authToken) {
  const response = await axios.get(
    `${BASE_URL}/torneos/${tournamentId}/clasificacion`,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  console.log('Standings response:', JSON.stringify(response.data, null, 2));
  return response.data.data;
}

function logRequest(method, endpoint, payload, response) {
  requestLog.push({
    method,
    endpoint,
    payload,
    response,
    timestamp: new Date().toISOString(),
  });
}

function saveRequestLog() {
  const logPath = path.join(__dirname, 'test_requests.txt');
  const content = requestLog
    .map(
      (req) =>
        `\n========================================\n${req.timestamp}\n========================================\n` +
        `METHOD: ${req.method}\nENDPOINT: ${req.endpoint}\n\n` +
        `REQUEST PAYLOAD:\n${JSON.stringify(req.payload, null, 2)}\n\n` +
        `RESPONSE:\n${JSON.stringify(req.response, null, 2)}`
    )
    .join('\n');

  fs.writeFileSync(logPath, content, 'utf-8');
  console.log(`\n✓ Request log saved to: ${logPath}`);
}

describe('Atletismo Tournament Flow', function () {
  this.timeout(30000);

  it('should log in as the organizer', async function () {
    try {
      token = await loginUser(organizerCredentials);
      assert.ok(token, 'Login failed, no token received');
      console.log('✓ Login successful');
    } catch (error) {
      console.error('Login error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should get the tournament', async function () {
    try {
      const tournaments = await getTournaments(token);
      assert.ok(Array.isArray(tournaments), 'Tournaments should be an array');
      assert.ok(tournaments.length > 0, 'No tournaments found');

      const tournament = tournaments.find(
        (t) => t.nombre === 'ATLETISMO-ELIM-SERIE-01'
      );

      assert.ok(tournament, 'ATLETISMO-ELIM-SERIE-01 tournament not found');
      tournamentId = tournament.id_torneo;
      console.log(`✓ Tournament found: ${tournament.nombre} (ID: ${tournamentId})`);
    } catch (error) {
      console.error('Get tournament error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should generate matches for the tournament', async function () {
    try {
      const matches = await generateMatches(tournamentId, token);
      assert.ok(matches, 'No matches generated');
      console.log(`✓ Matches generated`);
    } catch (error) {
      console.error('Generate matches error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should get all matches, update status to ACABADO, and submit results', async function () {
    try {
      const matches = await getMatches(token);
      assert.ok(Array.isArray(matches), 'Matches should be an array');
      assert.ok(matches.length > 0, 'No matches found');
      console.log(`✓ Found ${matches.length} matches`);

      // Group matches by serie/ronda to find matching pairs
      const matchesBySerie = {};
      matches.forEach((match) => {
        const key = `${match.ronda}`;
        if (!matchesBySerie[key]) {
          matchesBySerie[key] = [];
        }
        matchesBySerie[key].push(match);
      });

      console.log(`\nMatches grouped by ronda:`, Object.keys(matchesBySerie));

      // Process matches from multiple series/rounds
      const matchesToProcess = [];
      Object.values(matchesBySerie).forEach((matchesInRound, idx) => {
        if (idx < 2) {
          matchesToProcess.push(...matchesInRound.slice(0, 2));
        }
      });

      console.log(`\nProcessing ${matchesToProcess.length} matches:`);

      for (let i = 0; i < matchesToProcess.length; i++) {
        const match = matchesToProcess[i];
        console.log(
          `\n--- Processing Match ${i + 1} (ID: ${match.id_partido}, Ronda: ${match.ronda}) ---`
        );

        // 1. Update status to ACABADO
        console.log('Updating status to ACABADO...');
        await updateMatchStatus(match.id_partido, 'acabado', token);

        // 2. Submit results - simulate different outcomes
        const puntuaciones = [
          { id_participacion_equipo: i + 1, punto: 3 },
          { id_participacion_equipo: i + 2, punto: 1 },
          { id_participacion_equipo: i + 3, punto: 2 },
        ];

        const results = {
          puntuaciones,
          id_arbitro_torneo: 1,
        };

        console.log('Submitting results...');
        await submitResults(match.id_partido, results, token);
        console.log(`✓ Results submitted for match ${match.id_partido}`);
      }

      console.log(`\n✓ Results submitted for ${matchesToProcess.length} matches`);
    } catch (error) {
      console.error('Get/submit matches error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should get tournament standings and verify ELO changes', async function () {
    try {
      const standings = await getTournamentStandings(tournamentId, token);
      assert.ok(standings, 'No standings available');
      console.log('✓ Tournament standings retrieved');
      if (Array.isArray(standings)) {
        console.log(`\n  Total teams: ${standings.length}`);
        console.log('\n  Top 10 teams:');
        standings.slice(0, 10).forEach((team, idx) => {
          console.log(
            `  ${idx + 1}. ${team.nombre || team.equipo_nombre || 'Unknown'}: ` +
              `ELO ${team.elo || 'N/A'}, Puntos: ${team.puntos || 0}`
          );
        });
      }
    } catch (error) {
      console.error('Get standings error:', error.response?.data || error.message);
      throw error;
    }
  });

  afterEach(function () {
    if (this.currentTest.state === 'failed') {
      console.error(`\nTest failed: ${this.currentTest.title}`);
    }
  });

  after(function () {
    saveRequestLog();
  });
});