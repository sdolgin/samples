import React, { Component } from 'react';
import { SLAestimationTier } from './SLAestimationTier';
import './Styles.css';

export class SLAestimation extends Component {

    static renderSlaEstimationTier(tier, services, deleteEstimationTier, expandCollapseEstimationTier,
        deleteEstimationEntry, expandCollapseEstimationEntry, calculateTierSla, calculateDownTime) {
        return (
            <div>
                <SLAestimationTier tierName={tier} services={services}
                    onDeleteEstimationEntry={deleteEstimationEntry}
                    onExpandCollapseEstimationEntry={expandCollapseEstimationEntry}
                    onDeleteEstimationTier={deleteEstimationTier}
                    onExpandCollapseEstimationTier={expandCollapseEstimationTier}
                    calculateTierTotal={calculateTierSla}
                    calculateDownTime={calculateDownTime}
                />
            </div>
        );
    }

    render() {
        if (this.props.slaEstimationData.length > 0) {
            const tiers = ["Global", "Web", "Api", "Data", "Security", "Network"];
            var tierContents = [];

            for (var i = 0; i < tiers.length; i++) {
                var tierServices = this.props.slaEstimationData
                    .filter(o => o.tier === tiers[i])
                    .map(svc => svc.key);

                if (tierServices.length > 0) {
                    var tierContent = SLAestimation.renderSlaEstimationTier(tiers[i], tierServices,
                        this.props.onDeleteEstimationTier,
                        this.props.onExpandCollapseEstimationTier,
                        this.props.onDeleteEstimationEntry,
                        this.props.onExpandCollapseEstimationEntry,
                        this.props.calculateTierSla,
                        this.props.calculateDownTime);

                    tierContents.push(tierContent);
                }
            }

            return (
                <div>
                    <div className="estimation-toolbar">
                        <div className="estimation-expand-all" onClick={ev => this.props.onExpandAll(ev)}></div>
                        <div className="estimation-collapse-all" onClick={ev => this.props.onCollapseAll(ev)}></div>
                        <div className="estimation-delete-all" onClick={this.props.onDeleteAll}></div>
                    </div>
                    <br />
                    {tierContents}
                    <div>
                        <br />
                        <div className="estimation-totals-panel">
                            <br />
                            <div className="estimation-total-label"><p>Composite SLA: {this.props.slaTotal} %</p></div>
                            <div className="estimation-total-label"><p>Projected Max Minutes of Downtime/Month: {this.props.downTime} </p></div>
                            <br />
                            <div className="estimation-notes">Some services have special considerations when designing applications for availability and service level guarantees.  Review the Microsoft Azure Service Level Agreements documentation for details.</div>
                        </div>
                    </div>
                </div>
            );
        }

        return (<div></div>);
    }
}
