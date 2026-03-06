const { chromium } = require('playwright'); // You can also use firefox or webkit

async function downloadFilePlaywright() {
  const browser = await chromium.launch({ headless: false }); // Set headless to true for background execution
  const page = await browser.newPage();

  // Navigate to the page
  await page.goto('https://admin.found.no'); // Navigate to the admin page
  
  console.log('Browser opened. Please navigate to the page with the download button.');
  console.log('Login if necessary, then proceed to where the download button is located.');
  console.log('Waiting 300 seconds (5 minutes) for you to manually navigate and prepare...');
  
  // Give user time to login and navigate
  await page.waitForTimeout(300000);

  console.log('Now attempting to click the download button...');
  
  try {
    // Check if the button exists
    const button = await page.$('a.euiButtonEmpty.cui-1ae1iup-euiButtonDisplay-euiButtonEmpty-m-empty-primary');
    console.log('Button found:', !!button);
    
    if (!button) {
      console.log('Download button not found with the specified selector.');
      console.log('Let me try to find any download links on the page...');
      
      const allLinks = await page.$$('a[download]');
      console.log(`Found ${allLinks.length} links with download attribute`);
      
      console.log('Keeping browser open for 30 more seconds so you can inspect the page...');
      await page.waitForTimeout(30000);
      await browser.close();
      return;
    }

    console.log('Clicking the download button...');
    
    // Set up download listener
    const [download] = await Promise.all([
      page.waitForEvent('download', { timeout: 30000 }), // Wait for the download event
      page.click('a.euiButtonEmpty.cui-1ae1iup-euiButtonDisplay-euiButtonEmpty-m-empty-primary')
    ]);

    console.log('Download started! Suggested filename:', download.suggestedFilename());

    // Save the downloaded file with the expected filename
    const downloadPath = './downloads/';
    const filename = download.suggestedFilename() || 'logs-45d065-2026-Feb-12--09_30_47.zip';
    await download.saveAs(downloadPath + filename);
    console.log(`✅ File downloaded successfully to: ${downloadPath}${filename}`);
  } catch (error) {
    console.error('❌ Error during download:', error.message);
    console.log('Keeping browser open for 30 seconds so you can inspect...');
    await page.waitForTimeout(30000);
  }

  await browser.close();
}

downloadFilePlaywright();
