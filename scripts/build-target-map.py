# Generates the Appendix B target map for articles/one-record-one-projection.md from the binding appendix.
# Run from the repository root: python3 -I scripts/build-target-map.py (writes target_map.md and target_map.json to the working directory).
import re, json, sys
from collections import Counter, OrderedDict
src=open('articles/binding-the-three-maps.md').read()
app=src[src.index('## Appendix A'):src.index('## Sources')]
rows=[]
for l in app.splitlines():
    m=re.match(r'^\| (Spine|Record|Link|Reference|Seeing|Business|Task|Log) \| (.+?) \| (.*?) \| (.*?) \|$', l)
    if m: rows.append(dict(cls=m.group(1), name=m.group(2).replace('\\|','|').strip(), alias=m.group(3).replace('\\|','|').strip(), usage=m.group(4).strip()))
assert len(rows)==234, len(rows)

# actions: match (home holds the same records today), backfill (home exists, rows to load),
# document (becomes a projected document with an id), prose (human-written in Notion, swept in),
# retire (Supabase already holds the machine record; Notion copy archived), confirm (home not found)
R=[
 # --- Seeing
 (r'^IMG \| Image Reference', 'match', 'core.media_assets (+ media_rights_records)'),
 (r'INTAKE Image Intake', 'match', 'core.media_ingest_runs + intake.items'),
 (r'Project Images|Asset Library', 'backfill', 'core.media_assets + media_asset_variants'),
 (r'Pinterest Board', 'backfill', 'core.source_artifacts (pinterest_import_manifest) + arena_channels'),
 (r'Design Visuals|Design Reference Library|Material Studies', 'backfill', 'core.source_artifacts (design_reference, studio_material_reference) + visual_clusters'),
 (r'Zeitgeist|Cultural Reference|Design Movements Radar', 'match', 'core.visual_clusters + arena_channels + source_artifacts (study kinds)'),
 (r'Figma', 'match', 'design.template_registry + design.population_runs'),
 (r'3D & Visualization|Render & Visualization', 'document', 'core.source_artifacts (document) → projected page'),
 (r'Creative OS', 'retire', 'runtime.work_queue + core.work_definitions already hold the flow'),
 # --- Spine
 (r'Database Registry|Database Migration Queue|Database Audit', 'match', 'core.database_registry'),
 (r'Hub Registry|^DOC \| Hubs|Hub Governance', 'match', 'core.knowledge_registry'),
 (r'Category Registry|Tag Registry', 'match', 'core.classification_systems + classification_terms'),
 (r'Custom Agents|Staff & Virtual Employee|Staff Persona|Virtual Staff Registry|C-Suite Virtual Staff|Agent Definitions|Agent Cheat Sheets', 'match', 'memory.actors + runtime.agents + core.agent_skill_versions'),
 (r'Skills Index|System Notes, Skills', 'match', 'core.agent_skill_versions'),
 (r'AI Agents \+ Scheduler|Orchestration Pipeline|Orchestration Ops|Pipeline Steps', 'match', 'runtime.processor_registry + cron.job + core.work_definitions'),
 (r'Page Migration|System Build Queue|Testing & QA|Retroactive Scan', 'match', 'runtime.work_queue (class system)'),
 (r'Failure Class Library', 'match', 'core.agent_failure_subjects + agent_failure_events'),
 (r'Framework Design|SYSTEM Templates', 'document', 'core.source_artifacts (document) → projected page'),
 (r'Master Workflow \+ Database Connections', 'retire', 'core.database_registry + runtime.processor_registry supersede it'),
 (r'TRACKER \| Studies', 'match', 'core.observation_pilots + research.studies'),
 (r'TRACKER \| Tracked Projects', 'match', 'core.initiatives (+ initiative_projects)'),
 (r'Project Deliverables Registry|Deliverable Taxonomy|Deliverables by Phase|Deliverables by Sub Phase|Sheet Deliverables', 'match', 'core.phase_deliverable_expectations + deliverable_binding_rules'),
 # --- Record
 (r'Drawing Documentation Intelligence', 'match', 'core.deliverables + design.layout_manifests + design.sheet_revisions'),
 (r'Master Projects|Production Database|Design Workflow Projects', 'match', 'core.projects (+ project_phase_clusters)'),
 (r'Master Workflow|Workflow \+ Process|Sub Phase|Sub-Category|Phase Templates|Phase Code Master|Process Types|Milestone Definitions|Milestones/codes|AI Workflow Stages|Design Phase Template', 'match', 'core.phase_definitions + legacy_phase_crosswalk'),
 (r'^DOC \| Documents|Plan Drops|Plan Drop History', 'match', 'core.deliverables + deliverable_versions (registers DWG, PKG, RPT)'),
 (r'RFI Tracker', 'match', 'core.deliverables (register RFI → BUILD.02.02)'),
 (r'Submittal', 'match', 'core.deliverables (register SUB → BUILD.02.03)'),
 (r'Change Order', 'match', 'core.change_orders (register CO)'),
 (r'Construction Milestone|Work Orders', 'match', 'core.project_work_items'),
 (r'GC Budget|FF&E Budget', 'backfill', 'finance.project_budget_impacts + core.phase_economics_snapshots'),
 (r'Model Tracker', 'match', 'core.sketchup_models + project_model_of_record (register SKP)'),
 (r'Location Discovery', 'match', 'core.permit_cases + regulatory_assessments + parcels/premises'),
 (r'Written Specifications|Specifications by type', 'match', 'core.specifications + specification_classifications'),
 (r'Automation Engine', 'match', 'core.work_definitions'),
 (r'Billing Setup|Billing Threshold|Reimbursable|Invoices|Payments Received|Expense Tracking|Cost Tracking|Revenue Intelligence|Client Statement', 'backfill', 'finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone)'),
 (r'Occupancy', 'retire', 'no live use found; archive, re-create in finance if needed'),
 (r'Time Tracker|Time Tracking Codes', 'match', 'core.time_entries (+ classification_terms for codes)'),
 # --- Link
 (r'Decision Log|Decision Quality|Design Decision Tracker|Decision Memos', 'match', 'core.decisions + decision_links + governance_decisions'),
 (r'Publish Decision Log', 'match', 'core.release_events + content_publications'),
 (r'Handoff', 'match', 'runtime.work_context_bindings + memory.events'),
 (r'Discussion', 'prose', 'mirror.pages → outbound.meeting_snapshots / memory.items'),
 (r'Risk', 'backfill', 'core.decision_impacts + obligations (class risk)'),
 (r'Relation Map', 'match', 'core.link_graph_* (kphd-link-graph)'),
 (r'Soft Flags', 'match', 'core.agent_failure_events'),
 (r'KB Knowledge Change Proposals', 'match', 'core.reviewed_change_sets + guard.controlled_change_sets'),
 (r'Project Learnings|Project Lessons|Pattern Library', 'match', 'memory.items (class learning) + evidence_links'),
 # --- Task
 (r'Meeting Database', 'prose', 'mirror.pages → outbound.meeting_snapshots (register MTG)'),
 (r'Project Notes|Office Notes|Brandstorm Sprint', 'prose', 'mirror.pages → memory.items / intake.items (register NOTE)'),
 (r'CHECKLISTS|Work Blocks|Action Items|Intake Queue|Triage Queue|Agent Routing Queue|AI Issues', 'match', 'runtime.work_queue + intake.items'),
 (r'Email Inbox|Email Log|Email Action Tracker', 'match', 'core.gmail_attention_candidates + outbound.email_delivery_jobs'),
 (r'Output Tracker', 'match', 'outbound.email_delivery_jobs + core.content_publications'),
 (r'EVENT CALENDAR', 'match', 'outbound.event_occurrences'),
 (r'Daily Briefing', 'retire', 'runtime.v_processor_run_outcomes_v2 + digest receipts'),
 (r'Discovery Questions|Question Bank|Questionnaire', 'match', 'core.feasibility_client_briefs + restricted.pages (responses)'),
 # --- Business
 (r'Master Contacts|LinkedIn Contacts|Real Estate Brokers|Vendor Catalog|Vendor Directory', 'match', 'core.parties + party_contact_methods + party_role_bindings'),
 (r'Client Profiles|Client Pain Points|Client Engagement|Pre-Client Qualification|Unified CRM|Reconnaissance|Audience Research', 'match', 'core.parties + party_profiles + commercial_opportunities'),
 (r'Proposals|Proposal Workflow|Offer Groups|AI-Augmented Service Offerings|Service Offering Codes|Sales \+ Proposals', 'match', 'core.commercial_opportunities + offer_tiers + contract_versions'),
 (r'Content Ideas|Content Briefs|Content Pipeline|Social Media Writing|Marketing Operations|Messaging|Marketing \+ Sales Ops|Marketing Analytics|Newsletter', 'match', 'core.content_opportunities + content_publications + telemetry.content_signal_events'),
 (r'Market Intelligence|Strategy \+ Positioning|Sales Playbooks|Marketing Content|Mise en Place|Brand Messaging', 'document', 'core.source_artifacts (strategy_document) → projected page'),
 # --- Reference
 (r'Codes - Building|Codes - Technical|Permit Knowledge', 'match', 'core.external_authority_records + regulatory_assessments'),
 (r'Project Category|Project Classification|Task Sub-List', 'match', 'core.classification_systems + classification_terms'),
 (r'Deliverable Templates|Project Workflow Templates|Contract Templates', 'document', 'core.source_artifacts (template_catalog_capture) → projected page'),
 (r'Policies|Research \+ Protocols|Studio Procedures|Accounts \+ Procedures|Office Wiki|Office Process|PM Playbooks|Technical Guides|COE Operations|Architecture Docs|AI Agent Architecture|Prompt Engineering', 'match', 'core.agent_skill_versions + source_artifacts (protocol projection already in force)'),
 (r'SketchUp Standardization', 'match', 'core.classification_systems (tag taxonomy) + sketchup_component_definitions'),
 (r'Case Studies|Case Library|Core Curriculum|Reflection & Feedback|Executive Knowledge Base|Training Framework|Three-Lens|Design Position|Design Statements|Philosophy', 'document', 'core.source_artifacts (case_study, study_text) → projected page'),
 (r'Budget Reference Library', 'backfill', 'finance.project_budget_impacts reference set'),
 (r'Project Knowledge Base|Agent Behaviors|Validation Scenarios|Friday Systems Review', 'retire', 'core.agent_evaluation_* + runtime.v_work_health_v1 hold the live form'),
 # --- Log
 (r'Agent Performance|Error|Anomaly|Health Metrics|KPI|PULSEy|Stall|Flexibility|Audit|Chat Log|Experiments|System Performance|Virtual Staff Comms|OpenClaw|Client Data Incidents|Citation Index|AHJ', 'retire', 'core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases'),
 (r'Client Outcomes', 'backfill', 'core.observation_events (class outcome)'),
]
out=[]
for r in rows:
    act=home=None
    for pat,a,h in R:
        if re.search(pat, r['name']):
            act,home=a,h; break
    if act is None: act,home='confirm','no home found; needs a ruling'
    # class-level overrides for prose-type reference
    out.append(dict(**r, action=act, home=home))
c=Counter(o['action'] for o in out)
print(len(out), dict(c))
print('CONFIRM:', [o['name'] for o in out if o['action']=='confirm'])
json.dump(out, open('target_map.json','w'), indent=0)
# markdown appendix grouped by action order
order=['match','backfill','document','prose','retire','confirm']
md=[]
for a in order:
    grp=[o for o in out if o['action']==a]
    if not grp: continue
    md.append(f"\n### {a.capitalize()} ({len(grp)})\n\n| Class | Registered name | Supabase home |\n| --- | --- | --- |")
    for o in sorted(grp, key=lambda x:(x['cls'],x['name'])):
        md.append(f"| {o['cls']} | {o['name'].replace('|','\\\\|')} | {o['home']} |")
open('target_map.md','w').write('\n'.join(md))
# by class x action
tab=Counter((o['cls'],o['action']) for o in out)
cls=['Spine','Record','Link','Reference','Seeing','Business','Task','Log']
print('| Class | '+' | '.join(order)+' | total |')
for k in cls:
    print('| '+k+' | '+' | '.join(str(tab.get((k,a),0)) for a in order)+' | '+str(sum(tab.get((k,a),0) for a in order))+' |')
