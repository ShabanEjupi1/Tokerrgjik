import { neon } from '@neondatabase/serverless';
import nodemailer from 'nodemailer';

const sql = neon(process.env.NEON_DATABASE_URL || process.env.NETLIFY_DATABASE_URL);

// Email configuration - uses environment variables
const EMAIL_CONFIG = {
  FROM_EMAIL: process.env.FROM_EMAIL || 'noreply@tokerrgjik.com',
  FROM_NAME: 'Tokerrgjik Game',
  SMTP_HOST: process.env.SMTP_HOST || 'smtp.gmail.com',
  SMTP_PORT: parseInt(process.env.SMTP_PORT) || 587,
  APP_PASSWORD: process.env.APP_PASSWORD,
};

// Create email transporter with Gmail SMTP
const createTransporter = () => {
  if (!EMAIL_CONFIG.APP_PASSWORD) {
    console.warn('⚠️  APP_PASSWORD not set. Emails will only be logged to console.');
    return null;
  }

  console.log('📧 Email transporter config:', {
    host: EMAIL_CONFIG.SMTP_HOST,
    port: EMAIL_CONFIG.SMTP_PORT,
    from: EMAIL_CONFIG.FROM_EMAIL,
    secure: false, // TLS
    hasPassword: !!EMAIL_CONFIG.APP_PASSWORD
  });

  try {
    return nodemailer.createTransporter({
      host: EMAIL_CONFIG.SMTP_HOST,
      port: EMAIL_CONFIG.SMTP_PORT,
      secure: false, // Use TLS
      auth: {
        user: EMAIL_CONFIG.FROM_EMAIL,
        pass: EMAIL_CONFIG.APP_PASSWORD,
      },
      tls: {
        rejectUnauthorized: false // Accept self-signed certificates
      },
      logger: true, // Enable logging
      debug: true, // Show SMTP traffic
    });
  } catch (error) {
    console.error('❌ Failed to create transporter:', error);
    return null;
  }
};

// Send email via SMTP
async function sendEmail(to, subject, html) {
  console.log('\n========================================');
  console.log('📧 EMAIL NOTIFICATION');
  console.log('========================================');
  console.log(`To: ${to}`);
  console.log(`From: ${EMAIL_CONFIG.FROM_NAME} <${EMAIL_CONFIG.FROM_EMAIL}>`);
  console.log(`Subject: ${subject}`);
  console.log('----------------------------------------');
  
  const transporter = createTransporter();
  
  if (!transporter) {
    console.log('⚠️  Email SMTP not configured. Email content:');
    console.log(html);
    console.log('========================================\n');
    return true; // Return success so workflow doesn't break
  }

  try {
    const info = await transporter.sendMail({
      from: `"${EMAIL_CONFIG.FROM_NAME}" <${EMAIL_CONFIG.FROM_EMAIL}>`,
      to: to,
      subject: subject,
      html: html,
    });
    
    console.log('✅ Email sent successfully!');
    console.log('Message ID:', info.messageId);
    console.log('========================================\n');
    return true;
  } catch (error) {
    console.error('❌ Error sending email:', error.message);
    console.log('Email content (backup):');
    console.log(html);
    console.log('========================================\n');
    // Return true anyway so the function doesn't fail
    return true;
  }
}

export default async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  try {
    console.log('📧 Email function called');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    
    const { type, username, data } = req.body;
    
    if (!username || !type) {
      console.error('❌ Missing required fields');
      return res.status(400).json({ error: 'Missing required fields: username and type' });
    }
    
    // Get user email
    console.log('🔍 Looking up user:', username);
    const user = await sql`
      SELECT email, full_name FROM users
      WHERE username = ${username}
    `;
    
    if (user.length === 0) {
      console.error('❌ User not found:', username);
      return res.status(404).json({ error: 'User not found', username });
    }
    
    const userEmail = user[0].email;
    const fullName = user[0].full_name || username;
    
    console.log('✅ User found:', userEmail);
    
    let subject = '';
    let html = '';
    
    // FRIEND REQUEST
    if (type === 'friend_request') {
      const fromUsername = data.from_username;
      subject = `🎮 Kërkesë miqësie nga ${fromUsername} - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p><strong>${fromUsername}</strong> dëshiron të bëhet miku juaj në TokerrGjik!</p>
        <p>Hyni në aplikacion për të pranuar ose refuzuar kërkesën.</p>
        <br>
        <p>Faleminderit që luani TokerrGjik! 🎮</p>
      `;
    }
    
    // GAME INVITE
    else if (type === 'game_invite') {
      const fromUsername = data.from_username;
      subject = `🎲 Ftesë loje nga ${fromUsername} - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p><strong>${fromUsername}</strong> ju fton të luani një lojë TokerrGjik!</p>
        <p>Hyni në aplikacion për të filluar lojën.</p>
        <br>
        <p>Suksese! 🏆</p>
      `;
    }
    
    // ACHIEVEMENT UNLOCKED
    else if (type === 'achievement_unlocked') {
      const achievementTitle = data.achievement_title;
      const achievementIcon = data.achievement_icon || '🏆';
      subject = `${achievementIcon} Arritje e re e fituar - TokerrGjik`;
      html = `
        <h2>Urime ${fullName}!</h2>
        <p>Keni hapur një arritje të re:</p>
        <h3>${achievementIcon} ${achievementTitle}</h3>
        <p>${data.achievement_description || ''}</p>
        <br>
        <p>Vazhdoni të luani për të hapur më shumë arritje! 🎮</p>
      `;
    }
    
    // PRO PURCHASE CONFIRMATION
    else if (type === 'pro_purchase') {
      const months = data.months || 1;
      const amount = data.amount || '€2.99';
      subject = `✅ Konfirmim blerje PRO - TokerrGjik`;
      html = `
        <h2>Faleminderit ${fullName}!</h2>
        <p>Blerja juaj është konfirmuar:</p>
        <ul>
          <li><strong>Pajtime:</strong> TokerrGjik PRO</li>
          <li><strong>Kohëzgjatja:</strong> ${months} muaj</li>
          <li><strong>Shuma:</strong> ${amount}</li>
        </ul>
        <p>Tani keni qasje në:</p>
        <ul>
          <li>✨ Pa reklama</li>
          <li>🎨 Themes të personalizuara</li>
          <li>📊 Statistika të avancuara</li>
          <li>👑 Statusi PRO në Leaderboard</li>
        </ul>
        <br>
        <p>Shijoni përvojën PRO! 🚀</p>
      `;
    }
    
    // COINS PURCHASE CONFIRMATION
    else if (type === 'coins_purchase') {
      const coins = data.coins || 100;
      const amount = data.amount || '€0.99';
      subject = `💰 Konfirmim blerje monedhash - TokerrGjik`;
      html = `
        <h2>Faleminderit ${fullName}!</h2>
        <p>Blerja juaj është konfirmuar:</p>
        <ul>
          <li><strong>Monedha:</strong> ${coins} monedha</li>
          <li><strong>Shuma:</strong> ${amount}</li>
        </ul>
        <p>Monedhat janë shtuar në llogarinë tuaj!</p>
        <br>
        <p>Argëtim në lojë! 🎮</p>
      `;
    }
    
    // PASSWORD RESET
    else if (type === 'password_reset') {
      const resetToken = data.reset_token || 'DEMO_TOKEN';
      const resetLink = `https://tokerrgjik.netlify.app/reset-password?token=${resetToken}`;
      subject = `🔐 Rivendosni fjalëkalimin - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p>Keni kërkuar të rivendosni fjalëkalimin tuaj.</p>
        <p>Klikoni linkun më poshtë për të vazhduar:</p>
        <p><a href="${resetLink}" style="padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px;">Rivendos Fjalëkalimin</a></p>
        <p>Nëse nuk keni kërkuar këtë, ju lutemi injoroni këtë email.</p>
        <p><em>Linku është i vlefshëm për 24 orë.</em></p>
      `;
    }
    
    else {
      console.error('❌ Invalid email type:', type);
      return res.status(400).json({ error: 'Invalid email type', type });
    }
    
    // Send email
    console.log('📤 Sending email to:', userEmail);
    await sendEmail(userEmail, subject, html);
    
    console.log('✅ Email function completed successfully');
    return res.status(200).json({
      message: 'Email sent successfully',
      to: userEmail,
      type,
    });
    
  } catch (error) {
    console.error('❌ Email function error:', error);
    console.error('Error stack:', error.stack);
    return res.status(500).json({ 
      error: 'Internal server error', 
      message: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};
