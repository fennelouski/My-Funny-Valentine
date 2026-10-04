#!/usr/bin/env node
'use strict';
// Headless artifact composition only. No native app or user browser automation.
const fs=require('node:fs/promises'),path=require('node:path'),crypto=require('node:crypto'),os=require('node:os');
const root=__dirname,repo=path.resolve(root,'../../..');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
function owned(relative){const p=path.resolve(root,relative);if(!p.startsWith(root+path.sep))throw Error('Path escapes owned marketing leaf');return p;}
function pngSize(b){if(!b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error('Native PNG required');return[b.readUInt32BE(16),b.readUInt32BE(20)];}
function nativeSize(b,mediaType){
 if(mediaType==='image/png')return pngSize(b);
 if(mediaType!=='image/jpeg'||b[0]!==255||b[1]!==216)throw Error('Declared native image format mismatch');
 let offset=2;while(offset<b.length){if(b[offset++]!==255)throw Error('Invalid native JPEG marker');while(b[offset]===255)offset++;const marker=b[offset++];if(marker===217||marker===218)break;if(marker===1||marker>=208&&marker<=215)continue;const length=b.readUInt16BE(offset);if(length<2||offset+length>b.length)throw Error('Invalid native JPEG segment');if([192,193,194,195,197,198,199,201,202,203,205,206,207].includes(marker))return[b.readUInt16BE(offset+5),b.readUInt16BE(offset+3)];offset+=length;}
 throw Error('Native JPEG dimensions unavailable');
}
async function guardInputs(rows){for(const row of rows){const p=path.resolve(repo,row.path);if(!p.startsWith(repo+path.sep)||!/^[a-f0-9]{64}$/.test(row.sha256))throw Error('Invalid shipping input');if(hash(await fs.readFile(p))!==row.sha256)throw Error('Shipping input changed: '+row.path);}}
async function main(){
 const manifestBytes=await fs.readFile(owned('manifest.json')),manifest=JSON.parse(manifestBytes);
 if(manifest.preparationState!=='native-capture-inputs-approved')throw Error('Matching final native capture handoff is required; no placeholder rendering');
 if(!manifest.version||!manifest.build||!manifest.sourceFreeze)throw Error('Native version/build/freeze missing');
 const freezeBytes=await fs.readFile(owned(manifest.sourceFreeze.path));if(hash(freezeBytes)!==manifest.sourceFreeze.sha256)throw Error('Freeze snapshot changed');const freeze=JSON.parse(freezeBytes);if(!Array.isArray(freeze.shippingInputs)||!freeze.shippingInputs.length)throw Error('Exact shipping map required');await guardInputs(freeze.shippingInputs);
 if(manifest.scenes.length!==10||manifest.scenes.filter(s=>s.captureCount>1).length!==7||manifest.scenes.filter(s=>s.captureCount===1).length!==3||new Set(manifest.scenes.map(s=>s.background)).size!==4)throw Error('Gallery variation contract failed');
 for(let i=1;i<manifest.scenes.length;i++)if(manifest.scenes[i].background===manifest.scenes[i-1].background)throw Error('Adjacent backgrounds repeat');
 const font=await fs.readFile(owned(manifest.font.file));if(hash(font)!==manifest.font.sha256)throw Error('Pinned font changed');const license=await fs.readFile(owned(manifest.font.licensePath));if(hash(license)!==manifest.font.licenseSHA256)throw Error('Font license changed');
 const templateBytes=await fs.readFile(owned('index.html')),template=templateBytes.toString('utf8'),fontData='data:font/ttf;base64,'+font.toString('base64');
 // Dependency loading happens only after the source/capture approval gate.
 const {chromium}=require('playwright');let executablePath=chromium.executablePath();try{await fs.access(executablePath);}catch{const cache=path.join(os.homedir(),'Library/Caches/ms-playwright'),versions=(await fs.readdir(cache)).filter(n=>/^chromium_headless_shell-\d+$/.test(n)).sort((a,b)=>Number(b.split('-').pop())-Number(a.split('-').pop()));if(!versions.length)throw Error('Existing headless renderer unavailable');executablePath=path.join(cache,versions[0],'chrome-headless-shell-mac-arm64/chrome-headless-shell');}
 const proof={schemaVersion:1,status:'rendered-awaiting-individual-review-and-root-approval',renderedAtUTC:new Date().toISOString(),version:manifest.version,build:manifest.build,manifestSHA256:hash(manifestBytes),templateSHA256:hash(templateBytes),rendererSHA256:hash(await fs.readFile(__filename)),sourceFreeze:manifest.sourceFreeze,font:manifest.font,outputs:[]};
 const browser=await chromium.launch({headless:true,executablePath,args:['--disable-background-networking']});proof.browserVersion=browser.version();
 try{for(const[platformKey,platform]of Object.entries(manifest.platforms)){
  if(manifest.captureApproval[platformKey]!=='root-matching-native-handoff')throw Error('Missing '+platformKey+' native approval');await fs.mkdir(owned('exports/'+platformKey),{recursive:true});
  for(const scene of manifest.scenes){const rendering=structuredClone(manifest),renderScene=rendering.scenes.find(s=>s.id===scene.id),sources=[];
   for(const[role,state]of Object.entries(scene.captureRoles)){
    const id=platformKey+'-'+state,capture=rendering.captures[id];if(!capture||capture.platform!==platformKey||capture.nativeVersion!==manifest.version||capture.nativeBuild!==manifest.build||!capture.xcresult&&!capture.componentProvenance)throw Error('Matching native capture provenance missing: '+id);
    const bytes=await fs.readFile(owned(capture.path));if(hash(bytes)!==capture.sha256||nativeSize(bytes,capture.mediaType).join('x')!==capture.width+'x'+capture.height)throw Error('Native pixels changed: '+id);
    if(!Number.isInteger(capture.displayedWidth)||!Number.isInteger(capture.displayedHeight)||capture.displayedWidth<1||capture.displayedHeight<1)throw Error('Displayed orientation missing: '+id);
    capture.dataURL='data:'+capture.mediaType+';base64,'+bytes.toString('base64');const pose=renderScene.placements[platformKey][role];if(role==='hero'&&(pose.centerX!==50||pose.angle!==0)||role==='left'&&pose.angle>=0||role==='right'&&pose.angle<=0)throw Error('Hero/fan contract failed');
    if(role==='hero'){const maxHeight=platform.height*.975-platform.height*pose.top/100-12;pose.width=Math.min(pose.width,(maxHeight*capture.displayedWidth/capture.displayedHeight+12)/platform.width*100);}
    sources.push({id,role,path:capture.path,sha256:capture.sha256,nativeVersion:capture.nativeVersion,nativeBuild:capture.nativeBuild,xcresult:capture.xcresult??null,componentProvenance:capture.componentProvenance??null,displayedWidth:capture.displayedWidth,displayedHeight:capture.displayedHeight});
   }
   if(sources.length!==scene.captureCount||new Set(sources.map(s=>s.sha256)).size!==scene.captureCount)throw Error('Supporting captures must have distinct native pixels');rendering.render={platform:platformKey,scene:scene.id};
   const page=await browser.newPage({viewport:{width:platform.width,height:platform.height},deviceScaleFactor:1,reducedMotion:'reduce'});
   try{await page.route('**/*',route=>route.abort());await page.setContent(template.replace('__FONT_DATA__',fontData).replace('__GALLERY_DATA__',JSON.stringify(rendering).replaceAll('<','\\u003c')),{waitUntil:'load'});await page.evaluate(async()=>{await document.fonts.ready;if(!document.fonts.check('800 100px ValentineDisplay'))throw Error('Display font failed');await Promise.all([...document.images].map(i=>i.decode()));for(const i of document.images)if(i.naturalWidth!==Number(i.dataset.expectedWidth)||i.naturalHeight!==Number(i.dataset.expectedHeight))throw Error('EXIF displayed orientation mismatch');});
    const geometry=await page.evaluate(()=>{const rect=e=>{const r=e.getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height};};return{headline:rect(document.querySelector('.headline')),hero:rect(document.querySelector('.hero')),font:getComputedStyle(document.querySelector('.headline')).fontFamily,captures:[...document.querySelectorAll('.capture')].map(e=>({id:e.dataset.capture,role:e.dataset.role,rotation:Number(e.dataset.rotation),bounds:rect(e)}))};});
    if(geometry.headline.x<platform.width*.059||geometry.headline.x+geometry.headline.width>platform.width*.941)throw Error('Headline side margin failed');for(const capture of geometry.captures)if(geometry.headline.y+geometry.headline.height>capture.bounds.y-platform.height*.018)throw Error('Headline/capture separation failed');if(Math.abs(geometry.hero.x+geometry.hero.width/2-platform.width/2)>1||geometry.hero.y+geometry.hero.height>platform.height*.98)throw Error('Hero center/full-native-extent failed');
    const bytes=await page.screenshot({type:'png',omitBackground:false});if(pngSize(bytes).join('x')!==platform.width+'x'+platform.height||bytes[25]!==2)throw Error('Exact opaque RGB canvas required');const output='exports/'+platformKey+'/'+String(scene.ordinal).padStart(2,'0')+'-'+scene.id+'.png';await fs.writeFile(owned(output),bytes);proof.outputs.push({platform:platformKey,ordinal:scene.ordinal,scene:scene.id,path:output,sha256:hash(bytes),width:platform.width,height:platform.height,headline:scene.headline,background:scene.background,captureCount:scene.captureCount,sources,geometry,individualVisualReview:'pending',rootApproval:'pending'});
   }finally{await page.close();}
  }
 }}finally{await browser.close();}
 await guardInputs(freeze.shippingInputs);proof.productionGuard={inputCount:freeze.shippingInputs.length,before:'all-match',after:'all-match'};await fs.writeFile(owned('render-proof.json'),JSON.stringify(proof,null,2)+'\n');await fs.writeFile(owned('exports/preview.html'),template.replace('__FONT_DATA__',fontData).replace('__GALLERY_DATA__',JSON.stringify(manifest).replaceAll('<','\\u003c')));process.stdout.write(JSON.stringify({status:proof.status,images:proof.outputs.length})+'\n');
}
main().catch(error=>{process.stderr.write(error.stack+'\n');process.exitCode=1;});
