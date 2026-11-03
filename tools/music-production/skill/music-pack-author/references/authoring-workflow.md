# Authoring Workflow

## 1. Check overlap

Compare the requested profile to existing packs. Prefer adapting an existing pack when the production grammar, artifacts and evaluation target are already equivalent.

## 2. State the differentiator

Write one sentence of the form:

```text
This pack is justified because <production responsibility> changes from <existing grammar> to <new grammar>.
```

If that sentence only says the genre/mood is different, do not create the pack yet.

## 3. Define the production profile

Specify only fields that change behaviour. Avoid a universal schema filled with irrelevant null/default values.

## 4. Define core-skill effects

For each relevant skill, state what changes:

```text
music-compose  → search space / form / arrangement / draft strategy
music-produce  → realisation / model capabilities / refinement / delivery
music-evaluate → intentional traits / defects / routing
```

## 5. Define preservation

List the pack traits that should survive downstream production and the project decisions that outrank them.

## 6. Add showcase

Create at least one example README with a full prompt. The prompt should exercise the unique grammar, delivery and evaluation behaviour.

## 7. Add behavioural evals

Cover normal, draft, refinement, final and boundary cases. Include at least one negative case proving the pack is not applied aggressively when not requested.

## 8. Validate

Run the local validator where available and inspect the result manually. Passing structural validation does not prove creative quality.
