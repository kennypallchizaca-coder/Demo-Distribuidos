# Clean working tree and match 'main'
git rm -rfq .
git checkout main -- .

# Build Commit 1: Base Code (Replicas = 4)
(Get-Content k8s/deployment.yaml) -replace 'replicas: 12', 'replicas: 4' | Set-Content k8s/deployment.yaml
git add .
git commit -m "chore: inicializar codigo base de la practica"

# Build Commit 2: Defects (Reto 1, 2, 3 AND Broken test)
(Get-Content Dockerfile) -replace 'EXPOSE 3000', 'EXPOSE 8080' | Set-Content Dockerfile
(Get-Content k8s/deployment.yaml) -replace 'app: cicd-practica-sd', 'app: web' | Set-Content k8s/deployment.yaml
(Get-Content .github/workflows/ci-cd.yml) -replace 'needs: build-test', '' | Set-Content .github/workflows/ci-cd.yml
(Get-Content server.test.js) -replace 'assert.strictEqual\(res.status, 200\)', 'assert.strictEqual(res.status, 404)' | Set-Content server.test.js
git add .
git commit -m "feat: recrear artefactos con defectos iniciales (Reto 1, 2 y 3)"

# Build Commit 3: Fixes and Giro (12 replicas)
(Get-Content Dockerfile) -replace 'EXPOSE 8080', 'EXPOSE 3000' | Set-Content Dockerfile
(Get-Content k8s/deployment.yaml) -replace 'app: web', 'app: cicd-practica-sd' | Set-Content k8s/deployment.yaml
(Get-Content k8s/deployment.yaml) -replace 'replicas: 4', 'replicas: 12' | Set-Content k8s/deployment.yaml
(Get-Content .github/workflows/ci-cd.yml) -replace '    runs-on: ubuntu-latest', "    needs: build-test`n    runs-on: ubuntu-latest" | Set-Content .github/workflows/ci-cd.yml
(Get-Content server.test.js) -replace 'assert.strictEqual\(res.status, 404\)', 'assert.strictEqual(res.status, 200)' | Set-Content server.test.js
git add .
git commit -m "fix: resolver retos de simulacro y aplicar giro final (12 replicas)"

# Replace main and force push
git branch -D main
git checkout -b main
git push -f origin main
