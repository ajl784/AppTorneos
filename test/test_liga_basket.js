const assert = require('assert');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Base URL for the API
const BASE_URL = 'http://localhost:3000/api/v1';

// Test data - Usuarios
const organizadorCredentials = {
  correo: 'organizador_parchis@app.com',
  password: 'password123',
};

const arbitroCredentials = {
  correo: 'arbitro_parchis@app.com',
  password: 'password123',
};

const adminCredentials = {
  correo: 'admin@app.com',
  password: 'password123',
};

// Tokens y datos
let organizadorToken;
let arbitroToken;
let adminToken;
let tournamentId;
let arbitroTorneoId;
const requestLog = [];
let lastJornadaSignatures = [];

// Helper functions
async function loginUser(credentials) {
  const response = await axios.post(`${BASE_URL}/usuarios/login`, credentials);
  return response.data.data.token;
}

async function getTournaments(authToken) {
  const response = await axios.get(`${BASE_URL}/torneos`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  return response.data.data;
}

async function generateMatches(tournamentId, authToken) {
  const response = await axios.post(
    `${BASE_URL}/torneos/${Number(tournamentId)}/generar-enfrentamientos`,
    {},
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  return response.data.data;
}

async function getTournamentMatches(tournamentId, authToken) {
  const response = await axios.get(`${BASE_URL}/torneos/${Number(tournamentId)}/partidos`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  const payload = response.data.data;
  if (Array.isArray(payload)) {
    return payload;
  }
  return payload?.partidos || [];
}

async function updateMatchStatus(matchId, status, authToken) {
  const payload = { estado: status };
  const response = await axios.put(
    `${BASE_URL}/partidos/${Number(matchId)}`,
    payload,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  logRequest('PUT', `partidos/${matchId}`, payload, response.data);
  return response.data.data;
}

async function submitResults(matchId, results, authToken) {
  const response = await axios.post(
    `${BASE_URL}/partidos/${Number(matchId)}/puntuaciones`,
    results,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  logRequest('POST', `partidos/${matchId}/puntuaciones`, results, response.data);
  return response.data.data;
}

async function getTournamentStandings(tournamentId, authToken) {
  const response = await axios.get(
    `${BASE_URL}/torneos/${Number(tournamentId)}/clasificacion`,
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  const payload = response.data.data;
  return payload?.clasificacion || payload || [];
}

function normalizeMatches(matches) {
  return matches
    .filter((match) => match && match.jornada !== null && match.jornada !== undefined)
    .sort((left, right) => {
      if (left.jornada !== right.jornada) {
        return Number(left.jornada) - Number(right.jornada);
      }
      if (left.fecha_hora && right.fecha_hora) {
        return new Date(left.fecha_hora).getTime() - new Date(right.fecha_hora).getTime();
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

async function processJornada(matches, authToken, label) {
  const partidos = normalizeMatches(matches);
  assert.ok(partidos.length > 0, `${label}: no hay partidos para procesar`);

  console.log(`\n=== ${label} ===`);
  console.log(`Total partidos: ${partidos.length}`);

  let processedCount = 0;
  for (const match of partidos) {
    const equiposDisplay = (match.equipos || [])
      .map((team) => `${team.equipo_nombre}`)
      .join(' vs ');
    
    console.log(`  - Partido ${match.id_partido}: ${equiposDisplay}`);

    try {
      await updateMatchStatus(match.id_partido, 'acabado', authToken);
      const results = buildResultadosForMatch(match);
      await submitResults(match.id_partido, results, authToken);
      processedCount++;
    } catch (error) {
      console.error(`  Error procesando partido ${match.id_partido}:`, error.message);
    }
  }
  
  console.log(`✓ ${label}: Procesados ${processedCount}/${partidos.length} partidos`);
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
  const logPath = path.join(__dirname, 'test_requests_liga_basket.txt');
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

describe('Torneo Liga Parchís', function () {
  this.timeout(120000);

  it('should log in organizador', async function () {
    try {
      organizadorToken = await loginUser(organizadorCredentials);
      assert.ok(organizadorToken, 'Login failed, no token received');
      console.log('✓ Organizador login successful');
    } catch (error) {
      console.error('Organizador login error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should log in arbitro', async function () {
    try {
      arbitroToken = await loginUser(arbitroCredentials);
      assert.ok(arbitroToken, 'Arbitro login failed');
      console.log('✓ Arbitro login successful');
    } catch (error) {
      console.error('Arbitro login error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should log in admin', async function () {
    try {
      adminToken = await loginUser(adminCredentials);
      assert.ok(adminToken, 'Admin login failed');
      console.log('✓ Admin login successful');
    } catch (error) {
      console.error('Admin login error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should find Torneo Liga Parchís tournament', async function () {
    try {
      const tournaments = await getTournaments(organizadorToken);
      assert.ok(Array.isArray(tournaments), 'Tournaments should be an array');
      
      const tournament = tournaments.find((t) => t.nombre === 'Liga Parchís');
      
      if (tournament) {
        tournamentId = Number(tournament.id_torneo);
        console.log(`✓ Found tournament: ${tournament.nombre} (ID: ${tournamentId})`);
        console.log(`  Estado: ${tournament.estado}`);
        console.log(`  Organizador: ${tournament.id_organizador}`);
      } else {
        console.log('⚠ Tournament "Liga Parchís" not found. Please run setup_liga_basket_test.sql');
        console.log('  Available tournaments:');
        tournaments.slice(0, 5).forEach((t) => {
          console.log(`    - ${t.nombre} (${t.tipo_torneo_nombre})`);
        });
        throw new Error('Tournament "Liga Parchís" not found');
      }
    } catch (error) {
      console.error('Tournament search error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should generate matches for the tournament', async function () {
    try {
      const existingMatches = await getTournamentMatches(tournamentId, organizadorToken);
      if (existingMatches.length === 0) {
        console.log('Generating matches...');
        const matches = await generateMatches(tournamentId, organizadorToken);
        assert.ok(matches, 'No matches generated');
        console.log(`✓ Matches generated: ${existingMatches.length} total`);
      } else {
        console.log(`✓ Matches already exist with ${existingMatches.length} partidos`);
      }
    } catch (error) {
      console.error('Generate matches error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should process all jornadas and finish the league', async function () {
    try {
      let allMatches = await getTournamentMatches(tournamentId, arbitroToken);
      assert.ok(Array.isArray(allMatches), 'Matches should be an array');
      assert.ok(allMatches.length > 0, 'No matches found');

      console.log(`\nTotal matches in tournament: ${allMatches.length}`);

      // Obtener todas las jornadas disponibles
      const jornadasSet = new Set(
        allMatches
          .filter((m) => m.jornada !== null && m.jornada !== undefined)
          .map((m) => Number(m.jornada))
      );

      const jornadas = Array.from(jornadasSet).sort((a, b) => a - b);
      console.log(`Jornadas: ${jornadas.join(', ')}`);

      if (jornadas.length === 0) {
        console.log('⚠ No jornadas found in matches');
        return;
      }

      let totalMatchesProcessed = 0;

      for (const jornada of jornadas) {
        console.log(`\n--- JORNADA ${jornada} ---`);

        const jornadaMatches = allMatches.filter(
          (match) => Number(match.jornada) === jornada
        );

        if (jornadaMatches.length === 0) {
          console.log(`⚠ No matches found for jornada ${jornada}`);
          continue;
        }

        // Procesar todos los partidos de esta jornada
        await processJornada(jornadaMatches, arbitroToken, `Jornada ${jornada}`);
        totalMatchesProcessed += jornadaMatches.length;
      }

      console.log(`\n✓ LEAGUE COMPLETED: ${totalMatchesProcessed} total matches processed`);
    } catch (error) {
      console.error('Process jornadas error:', error.response?.data || error.message);
      throw error;
    }
  });

  it('should get tournament standings and verify final classification', async function () {
    try {
      const standings = await getTournamentStandings(tournamentId, organizadorToken);
      assert.ok(standings, 'No standings available');
      console.log('✓ Tournament standings retrieved');
      if (Array.isArray(standings)) {
        console.log(`\n  Total teams: ${standings.length}`);
        console.log('\n  FINAL CLASSIFICATION:');
        standings.forEach((team, idx) => {
          console.log(
            `  ${idx + 1}. ${team.nombre || team.equipo_nombre || 'Unknown'}: ` +
              `Pts: ${team.puntuacion || team.puntos || 0}, ` +
              `PJ: ${team.partidos_jugados || 0}`
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
      console.error(`\n✗ Test failed: ${this.currentTest.title}`);
    }
  });

  after(function () {
    saveRequestLog();
  });
});
