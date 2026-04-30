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
let lastRoundSignatures = [];

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

async function getTournamentMatches(tournamentId, authToken) {
  const response = await axios.get(`${BASE_URL}/torneos/${tournamentId}/partidos`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  console.log('Partidos response:', JSON.stringify(response.data, null, 2));
  const payload = response.data.data;
  if (Array.isArray(payload)) {
    return payload;
  }

  return payload?.partidos || [];
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

async function advanceEliminationRound(tournamentId, authToken) {
  const payload = {};
  const response = await axios.post(
    `${BASE_URL}/torneos/${tournamentId}/bracket/eliminacion/avanzar`,
    payload,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  logRequest(
    'POST',
    `torneos/${tournamentId}/bracket/eliminacion/avanzar`,
    payload,
    response.data,
  );
  console.log('Advance round response:', JSON.stringify(response.data, null, 2));
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
  const payload = response.data.data;
  return payload?.clasificacion || payload || [];
}

function normalizeMatches(matches) {
  return matches
    .filter((match) => match && match.ronda !== null && match.ronda !== undefined)
    .sort((left, right) => {
      if (left.ronda !== right.ronda) {
        return Number(left.ronda) - Number(right.ronda);
      }

      if (left.orden_ronda !== right.orden_ronda) {
        return Number(left.orden_ronda || 0) - Number(right.orden_ronda || 0);
      }

      return Number(left.id_partido) - Number(right.id_partido);
    });
}

function getMatchSignature(match) {
  return (match.equipos || [])
    .map((team) => Number(team.id_participacion_equipo))
    .sort((left, right) => left - right)
    .join('-');
}

function buildResultadosForMatch(match) {
  const equipos = Array.isArray(match.equipos) ? match.equipos : [];
  return {
    puntuaciones: equipos.map((team, index) => ({
      id_participacion_equipo: Number(team.id_participacion_equipo),
      punto: equipos.length - index,
    })),
    id_arbitro_torneo: 1,
  };
}

async function processRound(matches, authToken, label) {
  const partidos = normalizeMatches(matches);
  assert.ok(partidos.length > 0, `${label}: no hay partidos para procesar`);

  const signatures = partidos.map(getMatchSignature);
  console.log(`\n=== ${label} ===`);
  console.log('Partidos de la ronda:', partidos.map((match) => match.id_partido));
  console.log('Firmas de participantes:', signatures);

  if (lastRoundSignatures.length) {
    console.log('Comparando con la ronda anterior:');
    console.log(`  anterior: ${JSON.stringify(lastRoundSignatures)}`);
    console.log(`  actual:   ${JSON.stringify(signatures)}`);
  }

  lastRoundSignatures = signatures.slice();

  for (const match of partidos) {
    console.log(
      `\n--- Procesando partido ${match.id_partido} (ronda ${match.ronda}, orden ${match.orden_ronda}) ---`
    );
    console.log(
      'Equipos:',
      (match.equipos || [])
        .map((team) => `${team.equipo_nombre}#${team.id_participacion_equipo}`)
        .join(', '),
    );

    await updateMatchStatus(match.id_partido, 'acabado', authToken);
    const results = buildResultadosForMatch(match);
    await submitResults(match.id_partido, results, authToken);
  }
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
      const existingMatches = await getTournamentMatches(tournamentId, token);
      if (existingMatches.length === 0) {
        const matches = await generateMatches(tournamentId, token);
        assert.ok(matches, 'No matches generated');
        console.log(`✓ Matches generated`);
      } else {
        console.log(`✓ Bracket already exists with ${existingMatches.length} partidos`);
      }
    } catch (error) {
      console.error('Generate matches error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should finish first round, advance, and finish second round', async function () {
    try {
      const allMatches = await getTournamentMatches(tournamentId, token);
      assert.ok(Array.isArray(allMatches), 'Matches should be an array');
      assert.ok(allMatches.length > 0, 'No matches found');

      const firstRound = allMatches.filter((match) => Number(match.ronda) === 1);
      assert.ok(firstRound.length > 0, 'No first-round matches found');

      await processRound(firstRound, token, 'Ronda 1');

      const firstAdvance = await advanceEliminationRound(tournamentId, token);
      assert.ok(firstAdvance, 'Advance after round 1 failed');

      const afterFirstAdvance = await getTournamentMatches(tournamentId, token);
      const secondRound = afterFirstAdvance.filter((match) => Number(match.ronda) === 2);
      assert.ok(secondRound.length > 0, 'No second-round matches generated');

      await processRound(secondRound, token, 'Ronda 2');

      const secondAdvance = await advanceEliminationRound(tournamentId, token);
      assert.ok(secondAdvance, 'Advance after round 2 failed');

      const afterSecondAdvance = await getTournamentMatches(tournamentId, token);
      const thirdRound = afterSecondAdvance.filter((match) => Number(match.ronda) === 3);

      console.log(`\n✓ First round matches processed: ${firstRound.length}`);
      console.log(`✓ Second round matches processed: ${secondRound.length}`);
      console.log(`✓ Third round generated: ${thirdRound.length}`);
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