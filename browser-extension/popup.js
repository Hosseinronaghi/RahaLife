const api=globalThis.browser??globalThis.chrome;
let prepared=null;
const escape=(v)=>String(v).replace(/[&<>"']/g,(c)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
document.getElementById('export').addEventListener('click',async()=>{
 if(!prepared){
  const tree=await api.bookmarks.getTree();const links=[];
  const walk=(nodes)=>{for(const node of nodes){if(node.url&&/^https?:\/\//i.test(node.url))links.push(node);if(node.children)walk(node.children);}};walk(tree);
  prepared='<!DOCTYPE NETSCAPE-Bookmark-file-1><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8"><TITLE>Bookmarks</TITLE><DL>'+links.map((b)=>`<DT><A HREF="${escape(b.url)}">${escape(b.title)}</A>`).join('\n')+'</DL>';
  document.getElementById('count').textContent=`${links.length.toLocaleString('fa-IR')} نشانک آماده است. هیچ اطلاعاتی به سرور ارسال نمی‌شود.`;
  document.getElementById('export').textContent='ذخیرهٔ فایل HTML';return;
 }
 const url=URL.createObjectURL(new Blob([prepared],{type:'text/html;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download='Raha-Bookmarks.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
});
