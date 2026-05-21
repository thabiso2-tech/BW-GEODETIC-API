from fastapi import APIRouter
from app.core.adjustment import adjust_3d_baselines

router = APIRouter()

@router.post("/adjust")
async def perform_adjustment(data: dict):
    # Process points and baselines from the JSON payload
    points = {p['id']: [p['x'], p['y'], p['z'], p['fixed']] for p in data['points']}
    results = adjust_3d_baselines(points, data['baselines'])
    
    return {"status": "success", "corrections": results.tolist()}