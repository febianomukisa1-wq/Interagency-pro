from flask import Flask, render_template_string, request, redirect, jsonify, Response
import io, csv, datetime

app = Flask(__name__)
cases = []

HTML = """
<!DOCTYPE html>
<html><head><title>INTERAGENCY PRO</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0a4a7a">
<style>
body{font-family:Arial;background:#f4f7f9;margin:0}
.header{background:#0a4a7a;color:white;padding:15px;text-align:center}
.card{background:white;margin:12px;padding:15px;border-radius:12px;box-shadow:0 2px 8px #ccc}
.btn{display:block;width:100%;padding:14px;margin:8px 0;background:#0a4a7a;color:white;border:none;border-radius:10px;font-size:16px;text-align:center;text-decoration:none}
.btn-green{background:#1a8a4a}
.input{width:100%;padding:12px;margin:6px 0;border:1px solid #ccc;border-radius:8px;box-sizing:border-box}
.badge{padding:4px 10px;border-radius:20px;color:white;font-size:12px}
.high{background:#d32f2f}.medium{background:#f57c00}.low{background:#388e3c}
</style></head>
<body>
<div class="header"><h3>INTERAGENCY PRO - Kampala</h3></div>
<div class="card">
{% if page=='menu' %}
<h3>Main Menu</h3>
<a class="btn" href="/create">1. Create Case with Risk</a>
<a class="btn" href="/cases">2. View Cases ({{cases|length}})</a>
<a class="btn" href="/refer">3. Refer + WhatsApp</a>
<a class="btn" href="/dashboard">4. Dashboard</a>
<a class="btn" href="/export">5. Export CSV for MGLSD</a>
{% elif page=='create' %}
<h3>1. Create Case</h3>
<form method="POST">
<input class="input" name="name" placeholder="Client Name" required>
<input class="input" name="age" type="number" placeholder="Age" required>
<select class="input" name="gender"><option>Male</option><option>Female</option></select>
<select class="input" name="district"><option>Kampala</option><option>Wakiso</option><option>Mukono</option><option>Gulu</option><option>Other</option></select>
<select class="input" name="case_type">
<option>Child Protection</option><option>GBV</option>
<option>Street Child</option><option>Trafficking</option>
<option>Discrimination</option>
<option>Other Vulnerable</option>
</select>
<select class="input" name="risk" required>
<option value="High">High Risk - Immediate</option>
<option value="Medium">Medium Risk</option>
<option value="Low">Low Risk</option>
</select>
<textarea class="input" name="details" placeholder="Details..." required></textarea>
<button class="btn btn-green" type="submit">Save Case</button>
</form>
<a class="btn" href="/">Back</a>
{% elif page=='cases' %}
<h3>2. View Cases</h3>
{% for c in cases %}
<div style="border-bottom:1px solid #eee;padding:10px 0">
<b>{{c.name}}</b> ({{c.age}}y) - {{c.district}} <span class="badge {{c.risk|lower}}">{{c.risk}}</span><br>
<small>{{c.case_type}} | {{c.date}}<br>{{c.details}}</small>
</div>
{% else %}<p>No cases yet</p>{% endfor %}
<a class="btn" href="/">Back</a>
{% elif page=='refer' %}
<h3>3. Refer + WhatsApp</h3>
{% for c in cases %}
<div style="border:1px solid #ddd;padding:12px;margin:10px 0;border-radius:8px">
<b>{{c.name}}</b> <span class="badge {{c.risk|lower}}">{{c.risk}}</span><br>
<small>{{c.district}} - {{c.case_type}}</small><br><br>
<a class="btn btn-green" href="https://wa.me/?text=INTERAGENCY%20REFERRAL%20Name:%20{{c.name}}%20Age:%20{{c.age}}%20Risk:%20{{c.risk}}%20Type:%20{{c.case_type}}%20Details:%20{{c.details}}" target="_blank">WhatsApp Refer {{c.name}}</a>
</div>
{% endfor %}
<a class="btn" href="/">Back</a>
{% elif page=='dashboard' %}
<h3>4. Dashboard</h3>
<p>Total: <b>{{cases|length}}</b></p>
<p>High: {{cases|selectattr('risk','equalto','High')|list|length}} | Medium: {{cases|selectattr('risk','equalto','Medium')|list|length}} | Low: {{cases|selectattr('risk','equalto','Low')|list|length}}</p>
<a class="btn" href="/export">Download CSV</a>
<a class="btn" href="/">Back</a>
{% endif %}
</div></body></html>
"""

@app.route('/')
def menu(): return render_template_string(HTML, page='menu', cases=cases)

@app.route('/create', methods=['GET','POST'])
def create():
    if request.method=='POST':
        cases.append({'name':request.form['name'],'age':request.form['age'],'gender':request.form['gender'],'district':request.form['district'],'case_type':request.form['case_type'],'risk':request.form['risk'],'details':request.form['details'],'date':datetime.datetime.now().strftime('%Y-%m-%d %H:%M')})
        return redirect('/cases')
    return render_template_string(HTML, page='create', cases=cases)

@app.route('/cases')
def cases_view(): return render_template_string(HTML, page='cases', cases=cases)

@app.route('/refer')
def refer(): return render_template_string(HTML, page='refer', cases=cases)

@app.route('/dashboard')
def dashboard(): return render_template_string(HTML, page='dashboard', cases=cases)

@app.route('/export')
def export():
    output=io.StringIO(); writer=csv.writer(output)
    writer.writerow(['CaseID','Name','Age','Gender','District','CaseType','RiskLevel','Details','DateCreated','ReportingOrg','Status'])
    for i,c in enumerate(cases,1): writer.writerow([i,c['name'],c['age'],c['gender'],c['district'],c['case_type'],c['risk'],c['details'],c['date'],'Kampala Interagency','Open'])
    return Response(output.getvalue(), mimetype='text/csv', headers={"Content-Disposition":"attachment;filename=MGLSD_Export.csv"})

@app.route('/manifest.json')
def manifest(): return jsonify({"name":"INTERAGENCY PRO","short_name":"Interagency PRO","start_url":"/","display":"standalone","background_color":"#0a4a7a","theme_color":"#0a4a7a","icons":[{"src":"https://cdn-icons-png.flaticon.com/512/3067/3067513.png","sizes":"512x512","type":"image/png"}]})

if __name__=='__main__': app.run(host='0.0.0.0', port=5000)
